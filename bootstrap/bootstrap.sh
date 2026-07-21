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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --server-name) SERVER_NAME="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --jar) JAR_URL="$2"; shift 2 ;;
        --java-version) JAVA_VERSION="$2"; shift 2 ;;
        --mc-user) MC_USER="$2"; shift 2 ;;
        --mc-base-dir) MC_BASE_DIR="$2"; shift 2 ;;
        *) echo "[bootstrap] Unknown option: $1"; exit 1 ;;
    esac
done

[[ -z "$SERVER_NAME" ]] && { echo "[bootstrap] ERROR: --server-name required"; exit 1; }
[[ -z "$JAR_URL" ]] && { echo "[bootstrap] ERROR: --jar required"; exit 1; }

log() {
    echo "[bootstrap] $1"
}

MC_HOME="$MC_BASE_DIR/$SERVER_NAME"
SERVICE_NAME="minecraft-${SERVER_NAME}"

log "Deploying Minecraft server: $SERVER_NAME"
log "Home: $MC_HOME"
log "Port: $PORT, Memory: $MEMORY"

[[ $EUID -ne 0 ]] && { log "ERROR: Run as root"; exit 1; }

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
sudo -u "$MC_USER" cat > "$MC_HOME/eula.txt" <<EOF
eula=true
EOF

# server.properties
log "Creating server.properties..."
sudo -u "$MC_USER" cat > "$MC_HOME/server.properties" <<EOF
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
