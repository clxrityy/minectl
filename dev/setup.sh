#!/bin/bash

# Minectl development environment setup

set -euo pipefail

cd "$(dirname "$0")"

echo "Setting up minectl development environment..."
echo ""

# Check dependencies
for cmd in docker docker-compose; do
    if ! command -v $cmd &> /dev/null; then
        echo "✗ $cmd not found. Install Docker first."
        exit 1
    fi
done

# Build and start containers
echo "Building development containers..."
docker-compose build

echo "Starting services..."
docker-compose up -d

echo ""
echo "✓ Development environment ready!"
echo ""
echo "Containers:"
echo "  - minectl-client  (development client)"
echo "  - minectl-server1 (SSH: localhost:2222)"
echo "  - minectl-server2 (SSH: localhost:2223)"
echo ""
echo "Setup instructions:"
echo ""
echo "1. Enter client container:"
echo "   cd dev && docker-compose exec client bash"
echo ""
echo "2. Install minectl dependencies:"
echo "   dnf install -y openssh-clients curl"
echo ""
echo "3. Generate SSH key:"
echo "   ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''"
echo ""
echo "4. Copy key to servers:"
echo "   docker cp /root/.ssh/id_rsa.pub minectl-server1:/root/.ssh/authorized_keys"
echo "   docker cp /root/.ssh/id_rsa.pub minectl-server2:/root/.ssh/authorized_keys"
echo ""
echo "5. Test SSH (from inside client):"
echo "   ssh -o StrictHostKeyChecking=no root@minectl-server1"
echo ""
echo "6. Create minectl config:"
echo "   mkdir -p ~/.minectl"
echo "   cat > ~/.minectl/config <<EOF"
echo "CONFIG_DIR=/home/minecraft-servers"
echo "SSH_USER=minecraft-servers"
echo "EOF"
echo ""
echo "7. Initialize server:"
echo "   minectl init root@minectl-server1"
echo ""
echo "8. Create Minecraft server:"
echo "   minectl create-server root@minectl-server1 --server-name survival --memory 1G"
echo ""
echo "Stop environment:"
echo "   cd dev && docker-compose down"
