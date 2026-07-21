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
echo "=== SETUP FROM HOST (not inside container) ==="
echo ""
echo "1. Generate SSH key on host:"
echo "   ssh-keygen -t rsa -f ~/.ssh/minectl_dev -N ''"
echo ""
echo "2. Copy to servers (from host):"
echo "   docker cp ~/.ssh/minectl_dev.pub minectl-server1:/root/.ssh/authorized_keys"
echo "   docker cp ~/.ssh/minectl_dev.pub minectl-server2:/root/.ssh/authorized_keys"
echo ""
echo "3. Fix permissions on servers:"
echo "   docker-compose exec server1 chmod 600 /root/.ssh/authorized_keys"
echo "   docker-compose exec server2 chmod 600 /root/.ssh/authorized_keys"
echo ""
echo "=== ENTER CLIENT CONTAINER ==="
echo ""
echo "4. Enter client container:"
echo "   docker-compose exec client bash"
echo ""
echo "=== INSIDE CLIENT CONTAINER ==="
echo ""
echo "5. Install dependencies in client (inside container):"
echo "   dnf install -y openssh-clients curl"
echo ""
echo "6. From HOST: Copy SSH key to client:"
echo "   docker cp ~/.ssh/minectl_dev minectl-client:/root/.ssh/"
echo ""
echo "7. Inside client: Test SSH:"
echo "   ssh -o StrictHostKeyChecking=no -i ~/.ssh/minectl_dev root@minectl-server1"
echo ""
echo "8. Inside client: Create minectl config:"
echo "   mkdir -p ~/.minectl"
echo "   cat > ~/.minectl/config <<'EOF'"
echo "CONFIG_DIR=/home/minecraft-servers"
echo "SSH_USER=minecraft-servers"
echo "EOF"
echo ""
echo "9. Test minectl:"
echo "   minectl init root@minectl-server1"
echo "   minectl create-server root@minectl-server1 --server-name survival --memory 1G"
echo "   minectl list root@minectl-server1"
echo "   minectl start root@minectl-server1 --server-name survival"
echo "   minectl logs root@minectl-server1 --server-name survival"
echo ""
echo "=== CLEANUP ==="
echo ""
echo "Stop environment (from host):"
echo "  docker-compose down -v"
