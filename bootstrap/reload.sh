#!/bin/bash

# Remote reload script for server configurations
# Place at: /opt/minecraft/.minectl/reload.sh on Rocky Linux

set -euo pipefail

log() {
    echo "[minectl-reload] $1"
}

log "Reloading server configurations..."

MC_BASE_DIR="/opt/minecraft"
SERVERS_DIR="$MC_BASE_DIR/servers"

if [[ ! -d "$SERVERS_DIR" ]]; then
    log "No servers directory found."
    exit 0
fi

# Iterate through each server
for server_dir in "$SERVERS_DIR"/*/; do
    server_name=$(basename "$server_dir")
    config_file="$server_dir/.minectl/config.conf"
    service_name="minecraft-${server_name}"

    if [[ ! -f "$config_file" ]]; then
        log "Skipping $server_name (no config)"
        continue
    fi

    # Check if server is enabled
    enabled=$(grep -E "^ENABLED=" "$config_file" | cut -d= -f2 || echo "true")

    if [[ "$enabled" == "false" || "$enabled" == "off" ]]; then
        log "Disabling $server_name (ENABLED=$enabled)..."
        systemctl stop "$service_name" 2>/dev/null || true
        systemctl disable "$service_name" 2>/dev/null || true
    else
        log "Enabling $server_name..."
        systemctl enable "$service_name" 2>/dev/null || true
        systemctl start "$service_name" 2>/dev/null || true
    fi
done

log "Reload complete."
