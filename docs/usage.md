# Usage Guide

## Setup

1. Create client config:

   ```bash
   mkdir -p ~/.minectl
   cp config.template ~/.minectl/config
   ```

2. Edit `~/.minectl/config` with your remote config directory:

   ```conf
   CONFIG_DIR=/home/minecraft-servers
   SSH_USER=minecraft-servers
   ```

## Initialization

Initialize the remote host (creates base configuration interactively):

```bash
minectl init user@10.0.0.5
```

Prompts for:

- Minecraft user (default: `minecraft`)
- Minecraft base directory (default: `/opt/minecraft`)

## Creating Servers

```bash
minectl create-server user@10.0.0.5 --server-name survival --port 25565 --memory 4G
```

Options:

- `--server-name NAME` (required)
- `--port PORT` (default: 25565)
- `--memory MEMORY` (default: 2G)
- `--jar JAR_URL` (default: latest vanilla Minecraft)
- `--java-version VERSION` (default: 17)

Creates config and deploys the server.

## Import existing servers

Use this when a server already exists in `$MC_BASE_DIR/SERVER_NAME` and already has its own files, including `jvm.properties`.

- Doesn't download or replace server JAR
- Doesn't overwrite `server.properties`, `eula.txt`, worlds, or plugins
- Creates a systemd service that reads launch settings from `jvm.properties`
- Prompts for a remote Java executable path if `java` is not found automatically

```bash
minectl import-server user@10.0.0.5 --server-name earth-1
```

Supported `jvm.properties` keys for imported servers:

- `server_jar`
- `jvm_memory_max`
- `jvm_memory_min`
- `jvm_flags`

## Managing Servers

```bash
minectl start user@10.0.0.5 --server-name survival         # Start
minectl stop user@10.0.0.5 --server-name survival          # Stop
minectl status user@10.0.0.5 --server-name survival        # Check status
minectl logs user@10.0.0.5 --server-name survival          # View logs
minectl logs user@10.0.0.5 --server-name survival --follow # Follow logs
minectl list user@10.0.0.5                                 # List all servers
```

When using `minectl logs`, `minectl` prefers:

```conf
$MC_BASE_DIR/SERVER_NAME/logs/latest.log
```

when present and readable, and falls back to the server’s systemd journal otherwise.

## Validation

```bash
minectl validate user@10.0.0.5                             # Validate global config
minectl validate user@10.0.0.5 --server-name survival      # Validate server
```

## Direct Systemd Access

Each server is a systemd service named `minecraft-SERVER_NAME`. This is useful for manual inspection and troubleshooting:

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
