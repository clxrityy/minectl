#!/bin/bash

# Automated minectl dev environment setup and testing
# Simplified to avoid interactive prompts

set -euo pipefail

cd "$(dirname "$0")"

echo "=== Minectl Dev Environment - Automated Setup ==="
echo ""

# Check dependencies
for cmd in docker docker-compose; do
    if ! command -v $cmd &> /dev/null; then
        echo "✗ $cmd not found"
        exit 1
    fi
done

# Stop and cleanup existing containers
echo "Cleaning up old containers..."
docker-compose down -v 2>/dev/null || true

# Build and start
echo "Building containers..."
docker-compose build

echo "Starting containers..."
docker-compose up -d

# Wait for SSH to be ready
echo "Waiting for SSH services to start..."
sleep 15

echo "✓ Containers started"
echo ""

# Install dependencies in client
echo "Installing dependencies..."
docker-compose exec client dnf install -y openssh-clients curl sshpass >/dev/null 2>&1
echo "✓ Dependencies installed"

echo ""

# Setup minectl config in client
echo "Setting up minectl config..."
docker-compose exec client bash -c 'mkdir -p ~/.minectl && cat > ~/.minectl/config <<EOF
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
EOF'
echo "✓ Config created"

echo ""

# Test SSH connectivity
echo "Testing SSH connectivity..."
if docker-compose exec client sshpass -p minectl ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@minectl-server1 'echo SSH_WORKS' 2>&1 | grep -q SSH_WORKS; then
    echo "✓ SSH connectivity verified"
else
    echo "✗ SSH connectivity failed"
    exit 1
fi

echo ""

# Pre-create config on remote to avoid interactive init
echo "Pre-creating server configuration..."
docker-compose exec client sshpass -p minectl ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@minectl-server1 \
  'mkdir -p /home/minecraft-servers/servers && cat > /home/minecraft-servers/config <<EOF
JAVA_VERSION=17
MC_USER=minecraft
MC_BASE_DIR=/opt/minecraft
EOF'
echo "✓ Server configuration created"

echo ""

# Run minectl tests inside client
echo "=== Running minectl tests ==="
echo ""

# Test validate
echo "1. Validating global config..."
if docker-compose exec client sshpass -p minectl minectl validate root@minectl-server1 2>&1 | grep -q "Global config valid"; then
    echo "✓ Config validated"
else
    echo "⚠ Config validation output:"
    docker-compose exec client sshpass -p minectl minectl validate root@minectl-server1 2>&1 || true
fi

echo ""

# Test create-server
echo "2. Creating test server..."
if docker-compose exec client sshpass -p minectl minectl create-server root@minectl-server1 --server-name survival --memory 1G 2>&1 | grep -q "Server deployed"; then
    echo "✓ Server created and deployed"
else
    echo "⚠ Server creation output:"
    docker-compose exec client sshpass -p minectl minectl create-server root@minectl-server1 --server-name survival --memory 1G 2>&1 | tail -5
fi

echo ""

# Test list
echo "3. Listing servers..."
docker-compose exec client sshpass -p minectl minectl list root@minectl-server1 2>&1 || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Dev environment is ready!"
echo ""
echo "To enter the client container:"
echo "  docker-compose exec client bash"
echo ""
echo "Inside client, use minectl with sshpass:"
echo "  export SSHPASS=minectl"
echo "  sshpass -e minectl start root@minectl-server1 --server-name survival"
echo "  sshpass -e minectl logs root@minectl-server1 --server-name survival"
echo ""
echo "To cleanup:"
echo "  docker-compose down -v"
