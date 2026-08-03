#!/bin/bash

# Minectl development environment setup

set -euo pipefail

cd "$(dirname "$0")"

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
elif docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
else
    echo "✗ Neither docker-compose nor docker compose is available"
    exit 1
fi

compose() {
    "${COMPOSE[@]}" "$@"
}

echo "Setting up minectl development environment..."
echo ""

# Check dependencies
if ! command -v docker >/dev/null 2>&1; then
    echo "✗ docker not found. Install Docker first."
    exit 1
fi

# Build and start containers
echo "Building development containers..."
compose build

echo "Starting services..."
compose up -d

echo "=== MANUAL TEST FLOW ==="
echo ""
echo "1. Start the environment:"
echo "   docker compose up -d --build"
echo ""
echo "2. Wait for systemd and sshd:"
echo "   docker compose exec server1 systemctl is-system-running"
echo "   docker compose exec server1 systemctl is-active sshd"
echo ""
echo "3. Enter the client container:"
echo "   docker compose exec client bash"
echo ""
echo "4. Inside client, install helpers:"
echo "   dnf install -y openssh-clients curl sshpass"
echo ""
echo "5. Inside client, create client config:"
echo "   mkdir -p ~/.minectl"
echo "   cat > ~/.minectl/config <<'EOF'"
echo "CONFIG_DIR=/home/minecraft-servers"
echo "SSH_USER=minecraft-servers"
echo "EOF"
echo ""
echo "6. From inside client, test SSH:"
echo "   sshpass -p minectl ssh -o StrictHostKeyChecking=no root@minectl-server1"
echo ""
echo "7. Run the automated harness when ready:"
echo "   cd /minectl/test"
echo "   ./test.sh"
