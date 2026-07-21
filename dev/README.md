# Development Environment

Local Docker development environment for testing minectl.

## Quick Start

```bash
cd dev
chmod +x setup.sh
./setup.sh
```

This creates:

- `minectl-client` — Rocky Linux container with minectl CLI
- `minectl-server1` — SSH server for testing (port 2222)
- `minectl-server2` — SSH server for multi-server testing (port 2223)

## Manual Setup

```bash
# Start containers
cd dev
docker-compose up -d

# Enter client container
docker-compose exec client bash

# Inside client:
dnf install -y openssh-clients curl

# Generate SSH key
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''

# Copy to servers
docker cp ~/.ssh/id_rsa.pub minectl-server1:/root/.ssh/authorized_keys
docker cp ~/.ssh/id_rsa.pub minectl-server2:/root/.ssh/authorized_keys

# Test SSH
ssh -o StrictHostKeyChecking=no root@minectl-server1

# Setup minectl config
mkdir -p ~/.minectl
cat > ~/.minectl/config <<EOF
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
EOF

# Test minectl
minectl init root@minectl-server1
minectl create-server root@minectl-server1 --server-name survival --memory 1G
minectl list root@minectl-server1
minectl start root@minectl-server1 --server-name survival
minectl logs root@minectl-server1 --server-name survival
```

## Cleanup

```bash
cd dev
docker-compose down -v
```

## Testing Multiple Servers

```bash
# Create servers on both hosts
minectl create-server root@minectl-server1 --server-name s1 --port 25565 --memory 1G
minectl create-server root@minectl-server2 --server-name s2 --port 25565 --memory 1G

# List all
minectl list root@minectl-server1
minectl list root@minectl-server2

# Start all
minectl start root@minectl-server1 --server-name s1
minectl start root@minectl-server2 --server-name s2

# Check logs
minectl logs root@minectl-server1 --server-name s1 --follow
```

## Debugging

```bash
# View container logs
docker-compose logs -f server1

# SSH directly
ssh -o StrictHostKeyChecking=no -p 2222 root@localhost

# Check systemd services
docker-compose exec server1 systemctl list-units minecraft-*.service
```
