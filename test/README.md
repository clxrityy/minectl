# Development Environment

Local Docker development environment for testing minectl.

> [!NOTE]
> On macOS, this environment is recommended to run with [Colima](https://github.com/abiosoft/colima) because the test servers use `systemd`.
>
> Start Colima before running the test harness:
>
> ```bash
> colima start --cpu 4 --memory 8 --disk 40 --runtime docker
> docker context use colima
> ```

- [Quick Start](#quick-start)
- [Containers](#containers)
- [Usage](#usage)
- [File Structure](#file-structure)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Multi-Server Testing](#multi-server-testing)

---

## Quick Start

**Automated setup (recommended):**

```bash
cd test
chmod +x test.sh setup.sh
./test.sh
```

This automatically:

- Builds systemd-capable Rocky Linux test servers
- Configures SSH with password auth for automation (`root` / `minectl`)
- Sets up the client `minectl` config
- Verifies real `systemd` service management
- Tests both `create-server` and `import-server`
- Tests `jvm.properties`, file logs, and journal fallback
- Reports pass/fail results

**Manual setup:**

```bash
cd test
docker compose up -d
docker compose exec client dnf install -y openssh-clients curl sshpass
```

## Using Colima on macOS

If you're running this environment on macOS, start Colima first:

```bash
colima start --cpu 4 --memory 8 --disk 40 --runtime docker
docker context use colima
docker info
```

If the containers were previously created under a different Docker context, rebuild:

```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

To stop Colima when you're done:

```bash
colima stop
```

## Containers

**minectl-client** (Rocky Linux 8.6)

- Base Rocky Linux client used for running `minectl`
- Test harness installs `openssh-clients`, `curl`, and `sshpass`
- minectl CLI available
- Mount: working directory `/minectl`

**minectl-server1** (localhost:2222)

- Rocky Linux 8.6 with `systemd`
- `sshd` managed as a systemd service
- Java 17 pre-installed
- Test fixture jar available at `/opt/minectl-fixtures/fake-server.jar`
- Config dir: `/home/minecraft-servers`
- Server dir: `/opt/minecraft`
- SSH: `root` / `minectl`

**minectl-server2** (localhost:2223)

- Same as server1, separate instance

## Usage

### Enter client container

```bash
docker compose exec client bash
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

# Import existing server
sshpass -e minectl import-server root@minectl-server1 --server-name earth-1 --java-bin /usr/bin/java

# Validate imported server
sshpass -e minectl validate root@minectl-server1 --server-name earth-1

# Check logs of imported server
sshpass -e minectl logs root@minectl-server1 --server-name earth-1
```

## File Structure

```bash
test/
├── Dockerfile           # Rocky Linux 8.6 systemd-capable server image
├── docker-compose.yml   # Multi-container setup
├── test.sh              # Automated setup and tests
└── README.md            # This file
```

## Cleanup

```bash
docker compose down -v
```

## Troubleshooting

### SSH connection denied

```bash
# Check SSH server is running
docker compose exec server1 ps aux | grep sshd

# Try connecting with sshpass
export SSHPASS=minectl
sshpass -e ssh -o StrictHostKeyChecking=no root@minectl-server1
```

### Container won't start

```bash
# Check logs
docker compose logs server1

# Rebuild
docker compose down -v
docker compose build --no-cache
docker compose up -d server1 server2
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
