#!/bin/bash

# minectl configuration management library
# Centralized config at: /home/minecraft-servers/ (or custom path)

set -euo pipefail

# Colors for output
color_red() { echo -e "\033[0;31m$1\033[0m"; }
color_green() { echo -e "\033[0;32m$1\033[0m"; }
color_yellow() { echo -e "\033[0;33m$1\033[0m"; }
color_blue() { echo -e "\033[0;34m$1\033[0m"; }

# Get config directory (client-side or from server)
# Usage: get_config_dir [remote_user_host]
get_config_dir() {
    local remote="${1:-}"
    
    # Check client config first
    if [[ -f "$HOME/.minectl/config" ]]; then
        grep "^CONFIG_DIR=" "$HOME/.minectl/config" | cut -d= -f2 || echo "/home/minecraft-servers"
    else
        # Use server config
        if [[ -n "$remote" ]]; then
            ssh "$remote" "grep '^CONFIG_DIR=' /home/minecraft-servers/config 2>/dev/null | cut -d= -f2 || echo '/home/minecraft-servers'"
        else
            echo "/home/minecraft-servers"
        fi
    fi
}

# Load config file into associative array
load_config() {
    local config_file="$1"
    local -n config_ref="$2"

    [[ ! -f "$config_file" ]] && return 0

    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        config_ref["$key"]="$value"
    done < "$config_file"
}

# Validate required config keys
# Usage: validate_config <config_array> <required_keys...>
validate_config() {
    local -n config="$1"
    shift
    local -a required=("$@")
    local missing=()

    for key in "${required[@]}"; do
        if [[ -z "${config[$key]:-}" ]]; then
            missing+=("$key")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "$(color_red "✗ Missing required config keys:")"
        for key in "${missing[@]}"; do
            echo "  - $key"
        done
        return 1
    fi

    return 0
}

# Validate server config
# Usage: validate_server_config <config_array>
validate_server_config() {
    local -n config="$1"
    
    local required=(
        "ENABLED"
        "PORT"
        "MEMORY"
        "JAR_URL"
    )

    validate_config config "${required[@]}"
}

# Validate global config
# Usage: validate_global_config <config_array>
validate_global_config() {
    local -n config="$1"
    
    local required=(
        "JAVA_VERSION"
        "MC_USER"
        "MC_BASE_DIR"
    )

    validate_config config "${required[@]}"
}

# Load and validate server config
# Usage: load_server_config <config_dir> <server_name> <result_array>
load_server_config() {
    local config_dir="$1"
    local server_name="$2"
    local -n result="$3"

    local server_config_file="$config_dir/servers/$server_name.conf"

    if [[ ! -f "$server_config_file" ]]; then
        echo "$(color_red "✗ Server config not found: $server_config_file")"
        return 1
    fi

    load_config "$server_config_file" result

    if ! validate_server_config result; then
        return 1
    fi

    return 0
}

# Load and validate global config
# Usage: load_global_config <config_dir> <result_array>
load_global_config() {
    local config_dir="$1"
    local -n result="$2"

    local global_config_file="$config_dir/config"

    if [[ ! -f "$global_config_file" ]]; then
        echo "$(color_red "✗ Global config not found: $global_config_file")"
        return 1
    fi

    load_config "$global_config_file" result

    if ! validate_global_config result; then
        return 1
    fi

    return 0
}

# Get config value with validation
get_config_value() {
    local -n config="$1"
    local key="$2"
    
    if [[ -z "${config[$key]:-}" ]]; then
        echo "$(color_red "✗ Config key not set: $key")"
        return 1
    fi
    
    echo "${config[$key]}"
}

# Prompt for config value
prompt_config_value() {
    local key="$1"
    local default="${2:-}"
    local prompt_text="$key"

    if [[ -n "$default" ]]; then
        prompt_text="$key [$default]"
    fi

    read -p "$(color_blue "? $prompt_text: ")" value
    echo "${value:-$default}"
}

# List all servers from config
list_servers_from_config() {
    local config_dir="$1"
    local servers_dir="$config_dir/servers"

    if [[ ! -d "$servers_dir" ]]; then
        echo "$(color_yellow "No servers configured.")"
        return 0
    fi

    echo "$(color_green "Configured servers:")"
    for server_conf in "$servers_dir"/*.conf; do
        [[ -f "$server_conf" ]] || continue
        
        local server_name=$(basename "$server_conf" .conf)
        local enabled=$(grep "^ENABLED=" "$server_conf" | cut -d= -f2 || echo "unknown")
        local port=$(grep "^PORT=" "$server_conf" | cut -d= -f2 || echo "unknown")
        
        if [[ "$enabled" == "true" ]]; then
            echo "  $(color_green "✓") $server_name (port $port)"
        else
            echo "  $(color_red "✗") $server_name (port $port, disabled)"
        fi
    done
}
