# Development Environment

Local Docker development environment for testing minectl.

## Quick Start

**Automated setup (recommended):**

```bash
cd dev
chmod +x test.sh
./test.sh
```

This automatically:

- Builds and starts containers
- Configures SSH with password auth (minectl/minectl)
- Sets up minectl config
- Runs validation and server creation tests
- Reports results

**Manual setup:**

```bash
cd dev
docker-compose up -d
docker-compose exec client dnf install -y openssh-clients curl sshpass
```

## Containers

**minectl-client** (Rocky Linux 8.6)

- SSH client, curl, sshpass installed
- minectl CLI available
- Mount: working directory `/minectl`

**minectl-server1** (localhost:2222)

- Rocky Linux 8.6 with SSH server
- Java 17 pre-installed
- Config dir: `/home/minecraft-servers`
- Server dir: `/opt/minecraft`
- SSH: `root` / `minectl`

**minectl-server2** (localhost:2223)

- Same as server1, separate instance

## Usage

### Enter client container

```bash
docker-compose exec client bash
```

### SSH to server (from client)

```bash
sshpass -p minectl ssh root@minectl-server1
# or
export SSHPASS=minectl
sshpass -e ssh root@minectl-server1
```

### Test minectl commands

```bash
export SSHPASS=minectl

# Validate config
sshpass -e minectl validate root@minectl-server1

# Create server
sshpass -e minectl create-server root@minectl-server1 --server-name survival --memory 1G

# List servers
sshpass -e minectl list root@minectl-server1

# Start server
sshpass -e minectl start root@minectl-server1 --server-name survival

# Check logs
sshpass -e minectl logs root@minectl-server1 --server-name survival
```

## File Structure

```bash
dev/
├── Dockerfile           # Rocky Linux 8.6 client image
├── docker-compose.yml   # Multi-container setup
├── test.sh              # Automated setup and tests
└── README.md            # This file
```

## Cleanup

```bash
docker-compose down -v
```

## Troubleshooting

### SSH connection denied

```bash
# Check SSH server is running
docker-compose exec server1 ps aux | grep sshd

# Try connecting with sshpass
export SSHPASS=minectl
sshpass -e ssh -o StrictHostKeyChecking=no root@minectl-server1
```

### Container won't start

```bash
# Check logs
docker-compose logs server1

# Rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### minectl command not found

```bash
# minectl should be in PATH from host mount
which minectl
# Should show: /minectl/minectl

# Or use full path
/minectl/minectl version
```

## Multi-Server Testing

Create and manage multiple servers:

```bash
export SSHPASS=minectl

# Create on both servers
sshpass -e minectl create-server root@minectl-server1 --server-name s1 --memory 1G
sshpass -e minectl create-server root@minectl-server2 --server-name s2 --memory 1G

# Start both
sshpass -e minectl start root@minectl-server1 --server-name s1
sshpass -e minectl start root@minectl-server2 --server-name s2

# Check both
sshpass -e minectl logs root@minectl-server1 --server-name s1 --follow &
sshpass -e minectl logs root@minectl-server2 --server-name s2 --follow &
```
