# Usage Guide

## Setup

1. Create client config:
   ```bash
   mkdir -p ~/.minectl
   cp config.template ~/.minectl/config
   ```

2. Edit `~/.minectl/config` with your remote config directory:
   ```
   CONFIG_DIR=/home/minecraft-servers
   SSH_USER=minecraft-servers
   ```

## Initialization

Initialize the remote host (creates global config interactively):

```bash
minectl init user@10.0.0.5
```

Prompts for:
- Java version (default: 17)
- Minecraft user (default: minecraft)
- Minecraft base directory (default: /opt/minecraft)

## Creating Servers

```bash
minectl create-server user@10.0.0.5 --server-name survival --port 25565 --memory 4G
```

Options:
- `--server-name NAME` (required)
- `--port PORT` (default: 25565)
- `--memory MEMORY` (default: 2G)
- `--jar JAR_URL` (default: latest vanilla Minecraft)

Creates config and deploys the server.

## Managing Servers

```bash
minectl start user@10.0.0.5 --server-name survival         # Start
minectl stop user@10.0.0.5 --server-name survival          # Stop
minectl status user@10.0.0.5 --server-name survival        # Check status
minectl logs user@10.0.0.5 --server-name survival          # View logs
minectl logs user@10.0.0.5 --server-name survival --follow # Follow logs
minectl list user@10.0.0.5                                 # List all servers
```

## Validation

```bash
minectl validate user@10.0.0.5                             # Validate global config
minectl validate user@10.0.0.5 --server-name survival      # Validate server
```

## Direct Systemd Access

Each server is a systemd service named `minecraft-SERVER_NAME`:

```bash
ssh user@10.0.0.5
sudo systemctl start minecraft-survival
sudo systemctl stop minecraft-survival
sudo systemctl status minecraft-survival
sudo journalctl -u minecraft-survival -f
```

## Plugin Installation

Stop server, add plugins, restart:

```bash
minectl stop user@10.0.0.5 --server-name survival
ssh user@10.0.0.5 sudo cp my-plugin.jar /opt/minecraft/survival/plugins/
minectl start user@10.0.0.5 --server-name survival
```

## Multiple Servers

Create multiple independent servers on one machine:

```bash
minectl create-server user@10.0.0.5 --server-name survival --port 25565 --memory 4G
minectl create-server user@10.0.0.5 --server-name creative --port 25566 --memory 2G
minectl create-server user@10.0.0.5 --server-name minigames --port 25567 --memory 1G

minectl list user@10.0.0.5
minectl start user@10.0.0.5 --server-name survival
minectl start user@10.0.0.5 --server-name creative
minectl start user@10.0.0.5 --server-name minigames
```
