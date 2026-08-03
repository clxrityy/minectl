#!/bin/bash

# Rocky Linux bootstrap script for Minecraft server
# Deploys a server based on config parameters passed by minectl
# No config files are created here — all config is managed externally

set -euo pipefail

# Parse arguments
PORT=25565
MEMORY="2G"
JAR_URL=""
SERVER_NAME=""
JAVA_VERSION="17"
MC_USER="minecraft"
MC_BASE_DIR="/opt/minecraft"
IMPORT_EXISTING="false"
JAVA_BIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --server-name) SERVER_NAME="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --jar) JAR_URL="$2"; shift 2 ;;
        --java-version) JAVA_VERSION="$2"; shift 2 ;;
        --mc-user) MC_USER="$2"; shift 2 ;;
        --mc-base-dir) MC_BASE_DIR="$2"; shift 2 ;;
        --import-existing) IMPORT_EXISTING="$2"; shift 2 ;;
        --java-bin) JAVA_BIN="$2"; shift 2 ;;
        *) echo "[bootstrap] Unknown option: $1"; exit 1 ;;
    esac
done

MC_HOME="$MC_BASE_DIR/$SERVER_NAME"
SERVICE_NAME="minecraft-${SERVER_NAME}"

log() {
    echo "[bootstrap] $1"
}

[[ $EUID -ne 0 ]] && { log "ERROR: Run as root"; exit 1; }

create_import_launcher() {
    local launcher_path="/usr/local/bin/minectl-launch-${SERVER_NAME}"

    cat > "$launcher_path" <<EOF
#!/bin/bash
set -euo pipefail

SERVER_DIR="$MC_HOME"
JVM_PROPS="\$SERVER_DIR/jvm.properties"
JAVA_BIN="$JAVA_BIN"

[[ -f "\$JVM_PROPS" ]] || { echo "Missing jvm.properties: \$JVM_PROPS"; exit 1; }

read_prop() {
    local key="\$1"
    awk -F= -v wanted="\$key" '
        /^[[:space:]]*#/ { next }
        \$1 ~ ("^[[:space:]]*" wanted "[[:space:]]*$") {
            sub(/^[[:space:]]+/, "", \$2)
            sub(/[[:space:]]+$/, "", \$2)
            print \$2
            exit
        }
    ' "\$JVM_PROPS"
}

trim_quotes() {
    local value="\$1"
    value="\${value#\"}"
    value="\${value%\"}"
    echo "\$value"
}

SERVER_JAR=\$(trim_quotes "\$(read_prop server_jar)")
JVM_MEMORY_MAX=\$(trim_quotes "\$(read_prop jvm_memory_max)")
JVM_MEMORY_MIN=\$(trim_quotes "\$(read_prop jvm_memory_min)")

[[ -n "\$JVM_MEMORY_MAX" ]] || { echo "Missing jvm_memory_max in \$JVM_PROPS"; exit 1; }
[[ -n "\$JVM_MEMORY_MIN" ]] || { echo "Missing jvm_memory_min in \$JVM_PROPS"; exit 1; }

JVM_FLAGS=\$(trim_quotes "\$(read_prop jvm_flags)")

[[ -n "\$SERVER_JAR" ]] || { echo "Missing server_jar in \$JVM_PROPS"; exit 1; }
[[ -f "\$SERVER_DIR/\$SERVER_JAR" ]] || { echo "Server jar not found: \$SERVER_DIR/\$SERVER_JAR"; exit 1; }

[[ -x "\$JAVA_BIN" ]] || { echo "Java executable not found or not executable: \$JAVA_BIN"; exit 1; }

cd "\$SERVER_DIR"

BT_CHAR=\$(printf '\140')

if printf '%s\n' "\$JVM_FLAGS" | grep -Eq '[\$();&|<>]'; then
    echo "Unsupported characters in jvm_flags"
    exit 1
fi

if printf '%s\n' "\$JVM_FLAGS" | grep -Fq "\$BT_CHAR"; then
    echo "Unsupported characters in jvm_flags"
    exit 1
fi

read -r -a JVM_FLAG_ARRAY <<< "\$JVM_FLAGS"

exec "\$JAVA_BIN" \
  -Xmx"\$JVM_MEMORY_MAX" \
  -Xms"\$JVM_MEMORY_MIN" \
  "\${JVM_FLAG_ARRAY[@]}" \
  -jar "\$SERVER_DIR/\$SERVER_JAR" \
  nogui
EOF

    chmod 755 "$launcher_path"
}

[[ -z "$SERVER_NAME" ]] && { echo "[bootstrap] ERROR: --server-name required"; exit 1; }

if [[ "$IMPORT_EXISTING" == "true" ]]; then
    [[ -z "$JAVA_BIN" ]] && { echo "[bootstrap] ERROR: --java-bin required for import"; exit 1; }
else
    [[ -z "$JAR_URL" ]] && { echo "[bootstrap] ERROR: --jar required"; exit 1; }
fi

if [[ "$IMPORT_EXISTING" == "true" ]]; then
    [[ -d "$MC_HOME" ]] || { log "ERROR: Existing server directory not found: $MC_HOME"; exit 1; }
    [[ -f "$MC_HOME/jvm.properties" ]] || { log "ERROR: Missing jvm.properties: $MC_HOME/jvm.properties"; exit 1; }

    if ! id "$MC_USER" &>/dev/null; then
        log "ERROR: Minecraft user does not exist: $MC_USER"
        exit 1
    fi

    create_import_launcher

    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Minecraft Server ($SERVER_NAME)
After=network.target

[Service]
Type=simple
User=$MC_USER
WorkingDirectory=$MC_HOME
ExecStart=/usr/local/bin/minectl-launch-${SERVER_NAME}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"

    log "Import complete!"
    exit 0
fi

log "Deploying Minecraft server: $SERVER_NAME"
log "Home: $MC_HOME"
log "Port: $PORT, Memory: $MEMORY"


# Install Java
log "Installing Java $JAVA_VERSION..."
dnf install -y java-${JAVA_VERSION}-openjdk-headless

# Create user
log "Creating user: $MC_USER"
if ! id "$MC_USER" &>/dev/null; then
    useradd -r -s /bin/bash "$MC_USER"
fi

# Create directories
log "Creating server directory: $MC_HOME"
mkdir -p "$MC_HOME"/{plugins,world}
chown -R "$MC_USER:$MC_USER" "$MC_HOME"

cd "$MC_HOME"

# Download JAR
log "Downloading server JAR..."
sudo -u "$MC_USER" curl -o "$MC_HOME/server.jar" -L "$JAR_URL"

# EULA
log "Accepting EULA..."
cat <<EOF | sudo -u "$MC_USER" tee "$MC_HOME/eula.txt" >/dev/null
eula=true
EOF

# server.properties
log "Creating server.properties..."
cat <<EOF | sudo -u "$MC_USER" tee "$MC_HOME/server.properties" >/dev/null
server-port=$PORT
max-players=20
online-mode=true
gamemode=survival
difficulty=normal
pvp=true
EOF

# Create systemd service
log "Installing systemd service: $SERVICE_NAME"
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Minecraft Server ($SERVER_NAME)
After=network.target

[Service]
Type=simple
User=$MC_USER
WorkingDirectory=$MC_HOME
ExecStart=/usr/bin/java -Xmx$MEMORY -Xms$MEMORY -jar $MC_HOME/server.jar nogui
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

log "Deployment complete!"
log "Service: $SERVICE_NAME"
log "Start: sudo systemctl start $SERVICE_NAME"
log "Logs: sudo journalctl -u $SERVICE_NAME -f"
