#!/bin/bash

# minectl configuration management
# Handles client and server configs with priority: server > client

# Colors for output
COLOR_ENABLED="${COLORED_OUTPUT:-true}"

color_red() { [[ "$COLOR_ENABLED" == "true" ]] && echo -e "\033[0;31m$1\033[0m" || echo "$1"; }
color_green() { [[ "$COLOR_ENABLED" == "true" ]] && echo -e "\033[0;32m$1\033[0m" || echo "$1"; }
color_yellow() { [[ "$COLOR_ENABLED" == "true" ]] && echo -e "\033[0;33m$1\033[0m" || echo "$1"; }
color_blue() { [[ "$COLOR_ENABLED" == "true" ]] && echo -e "\033[0;34m$1\033[0m" || echo "$1"; }

# Load config file into associative array
# Usage: load_config <path> <array_name>
load_config() {
    local config_file="$1"
    local -n config_ref="$2"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue

        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        config_ref["$key"]="$value"
    done < "$config_file"
}

# Write config to file
# Usage: write_config <path> <array_name>
write_config() {
    local config_file="$1"
    local -n config_ref="$2"

    mkdir -p "$(dirname "$config_file")"

    {
        echo "# minectl configuration"
        echo "# Generated: $(date)"
        echo ""
        for key in "${!config_ref[@]}"; do
            echo "${key}=${config_ref[$key]}"
        done
    } > "$config_file"
}

# Merge two configs: priority over base
# Usage: merge_configs <base_array> <priority_array> <result_array>
merge_configs() {
    local -n base="$1"
    local -n priority="$2"
    local -n result="$3"

    # Copy base first
    for key in "${!base[@]}"; do
        result["$key"]="${base[$key]}"
    done

    # Override with priority
    for key in "${!priority[@]}"; do
        result["$key"]="${priority[$key]}"
    done
}

# Get config value with fallback
# Usage: get_config <config_array> <key> [default]
get_config() {
    local -n config="$1"
    local key="$2"
    local default="${3:-}"

    if [[ -v config["$key"] ]]; then
        echo "${config[$key]}"
    else
        echo "$default"
    fi
}

# Detect config conflicts and prompt user
# Usage: prompt_override <server_name> <key> <server_value> <client_value>
# Returns: 0 if use server, 1 if use client
prompt_override() {
    local server_name="$1"
    local key="$2"
    local server_value="$3"
    local client_value="$4"

    echo ""
    echo "$(color_yellow "⚠ Config conflict for '$server_name':")"
    echo "  $(color_blue "Server config ($key):")" $(color_green "$server_value")
    echo "  $(color_blue "Your config ($key):")"   $(color_red "$client_value")
    echo ""
    echo "Use server config? (y/n) [default: y]"
    read -r response
    [[ -z "$response" || "$response" == "y" || "$response" == "Y" ]]
}

# Get effective config for a server (merges client + server + per-server)
# Usage: get_server_config <remote_user_host> <server_name> <result_array_name>
get_server_config() {
    local remote_user_host="$1"
    local server_name="$2"
    local -n result="$3"

    declare -A client_config
    declare -A server_config
    declare -A perserver_config

    # 1. Load client config
    load_config "$HOME/.minectl/config.conf" client_config

    # 2. Load server global config (remote)
    ssh "$remote_user_host" "cat /opt/minecraft/.minectl/config.conf 2>/dev/null || echo ''" | while read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        local key="${line%%=*}"
        local value="${line##*=}"
        server_config["$key"]="$value"
    done

    # 3. Load per-server config (remote)
    ssh "$remote_user_host" "cat /opt/minecraft/servers/$server_name/.minectl/config.conf 2>/dev/null || echo ''" | while read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        local key="${line%%=*}"
        local value="${line##*=}"
        perserver_config["$key"]="$value"
    done

    # 4. Merge: perserver > server > client
    merge_configs client_config server_config result
    merge_configs result perserver_config result
}

# Reload server configuration on remote
# Usage: reload_server_config <remote_user_host>
reload_server_config() {
    local remote_user_host="$1"

    echo "[minectl] Reloading server configurations on $remote_user_host..."
    ssh "$remote_user_host" "sudo /opt/minecraft/.minectl/reload.sh"

    if [[ $? -eq 0 ]]; then
        echo "[minectl] $(color_green "Reload successful.")"
    else
        echo "[minectl] $(color_red "Reload failed. Check server logs.")"
    fi
}

# List servers with their status from config
# Usage: list_servers_from_config <remote_user_host>
list_servers_from_config() {
    local remote_user_host="$1"

    echo "[minectl] Servers on $remote_user_host:"
    ssh "$remote_user_host" "for dir in /opt/minecraft/servers/*/; do \
        server_name=\$(basename \$dir); \
        status_file=\"/opt/minecraft/.minectl/\${server_name}.status\"; \
        if grep -q 'ENABLED=true' \$dir/.minectl/config.conf 2>/dev/null; then \
            echo \"  ✓ \$server_name (enabled)\"; \
        else \
            echo \"  ✗ \$server_name (disabled)\"; \
        fi; \
    done"
}
