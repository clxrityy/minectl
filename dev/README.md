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
- Generates SSH keys
- Configures minectl
- Runs tests
- Reports results

**Manual setup:**

```bash
cd dev
chmod +x setup.sh
./setup.sh

# If updating after changes:
docker-compose down -v
docker-compose up -d
```

This creates:

- `minectl-client` — Rocky Linux container with minectl CLI
- `minectl-server1` — SSH server (port 2222)
- `minectl-server2` — SSH server (port 2223)

## Setup Process

### 1. Run setup script (from host)

```bash
cd dev
./setup.sh
```

### 2. Generate SSH key (from host)

```bash
ssh-keygen -t rsa -f ~/.ssh/minectl_dev -N ''
```

### 3. Copy to servers (from host)

```bash
docker cp ~/.ssh/minectl_dev.pub minectl-server1:/root/.ssh/authorized_keys
docker cp ~/.ssh/minectl_dev.pub minectl-server2:/root/.ssh/authorized_keys

# Fix permissions
docker-compose -f dev/docker-compose.yml exec server1 chmod 600 /root/.ssh/authorized_keys
docker-compose -f dev/docker-compose.yml exec server2 chmod 600 /root/.ssh/authorized_keys
```

### 4. Enter client container (from host)

```bash
docker-compose -f dev/docker-compose.yml exec client bash
```

### 5. Inside client: Install and configure

```bash
# Install SSH client
dnf install -y openssh-clients curl

# Copy SSH key to client (from host in new terminal)
docker cp ~/.ssh/minectl_dev minectl-client:/root/.ssh/

# Create minectl config
mkdir -p ~/.minectl
cat > ~/.minectl/config <<EOF
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
EOF
```

### 6. Test SSH (inside client)

```bash
# Using container hostname (works inside docker network)
ssh -o StrictHostKeyChecking=no -i ~/.ssh/minectl_dev root@minectl-server1

# Or using localhost with port (from host)
ssh -o StrictHostKeyChecking=no -i ~/.ssh/minectl_dev -p 2222 root@localhost
```

### 7. Test minectl (inside client)

```bash
# minectl uses SSH internally, so it should work with container hostnames
minectl init root@minectl-server1
minectl create-server root@minectl-server1 --server-name survival --memory 1G
minectl list root@minectl-server1
minectl start root@minectl-server1 --server-name survival
minectl logs root@minectl-server1 --server-name survival
```

## Containers

### `minectl-client`

- Rocky Linux 8.6
- SSH client installed
- minectl CLI available
- Mount: working directory `/minectl`

### `minectl-server1` (localhost:2222)

- Rocky Linux 8.6 with SSH server
- Java 17 pre-installed
- Config dir: `/home/minecraft-servers`
- Server dir: `/opt/minecraft`

### `minectl-server2` (localhost:2223)

- Same as server1, separate instance

## Cleanup

```bash
docker-compose -f dev/docker-compose.yml down -v
```

## Troubleshooting

### SSH Connection Refused

```bash
# Inside client: use container hostname
ssh -o StrictHostKeyChecking=no -i ~/.ssh/minectl_dev root@minectl-server1

# From host: use localhost with mapped port
ssh -o StrictHostKeyChecking=no -i ~/.ssh/minectl_dev -p 2222 root@localhost

# Check server is running
docker-compose -f dev/docker-compose.yml ps

# Check SSH is listening
docker-compose -f dev/docker-compose.yml exec server1 ss -tlnp | grep 22

# Check key permissions
docker-compose -f dev/docker-compose.yml exec server1 ls -la /root/.ssh/
```

### Can't find minectl in client

```bash
# minectl should be in PATH from host mount
# Inside client:
which minectl
# Should show: /minectl/minectl

# If not, add to PATH:
export PATH="/minectl:$PATH"
minectl version
```

### Docker command not found inside client

You're inside a container — docker commands only work on the host. Use `docker-compose` from the host instead.

## Multi-Server Testing

```bash
# Create on both servers
minectl create-server root@minectl-server1 --server-name s1
minectl create-server root@minectl-server2 --server-name s2

# List both
minectl list root@minectl-server1
minectl list root@minectl-server2

# Start both
minectl start root@minectl-server1 --server-name s1
minectl start root@minectl-server2 --server-name s2

# Check both
minectl logs root@minectl-server1 --server-name s1 --follow &
minectl logs root@minectl-server2 --server-name s2 --follow &
```
