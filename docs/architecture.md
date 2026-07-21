# Architecture

## Overview

minectl manages Minecraft servers through centralized configuration on the remote host. The client specifies where configs live via `~/.minectl/config`.

## Config Authority

- **Client config** (`~/.minectl/config`): Specifies `CONFIG_DIR` on remote
- **Server config** (`$CONFIG_DIR/`): All server configs live here, server-side authoritative
- **Client access**: Read-only via minectl commands; no direct file modification

## Config Directory

Located on the remote host at path specified by `CONFIG_DIR` in `~/.minectl/config`.

```conf
$CONFIG_DIR/
├── config                    # Global settings (JAVA_VERSION, MC_USER, MC_BASE_DIR)
└── servers/
    ├── survival.conf         # Server configs (ENABLED, PORT, MEMORY, JAR_URL)
    ├── creative.conf
    └── minigames.conf
```

The SSH user IS the directory owner — configs stored in their home or accessible directory.

## Server Directories (separate from configs)

```conf
$MC_BASE_DIR/                 # From global config
├── survival/
│   ├── server.jar
│   ├── eula.txt
│   ├── server.properties
│   ├── plugins/
│   └── world/
├── creative/
│   ├── server.jar
│   ├── plugins/
│   └── world/
└── minigames/
    ├── plugins/
    └── world/
```

## Systemd Services

Each server gets a systemd service named `minecraft-SERVER_NAME`:

- Type: simple, auto-restart on crash
- User: specified in global config (default: `minecraft`)
- WorkingDirectory: `$MC_BASE_DIR/SERVER_NAME`
- Auto-enabled on boot

VPN not required after deployment — servers persist across reboots via systemd.

## Deployment Flow

1. **Client setup**: Create `~/.minectl/config` with `CONFIG_DIR`
2. **Init**: `minectl init user@host` creates `$CONFIG_DIR/config` with global settings
3. **Create**: `minectl create-server user@host --server-name NAME` writes server config and runs bootstrap
4. **Bootstrap**: Installs Java, creates directories, downloads JAR, creates systemd service
5. **Manage**: `minectl start/stop/logs` controls servers via systemd

## Configuration Files

**Global Config** (`$CONFIG_DIR/config`):

- `JAVA_VERSION`: Java version to install
- `MC_USER`: Unix user running servers
- `MC_BASE_DIR`: Base directory for all servers

**Per-Server Config** (`$CONFIG_DIR/servers/SERVER_NAME.conf`):

- `ENABLED`: true/false
- `PORT`: Server port
- `MEMORY`: JVM memory (e.g., 4G)
- `JAR_URL`: URL to server JAR

All keys are required. Validation fails if any key is missing.

## Client Config

**File**: `~/.minectl/config`

- `CONFIG_DIR`: Path on remote where server configs live
- `SSH_USER`: SSH user for deployment

## Requirements

- Local: bash, ssh, scp, curl
- Remote: Rocky Linux, sudo access, ~10GB disk per server
- SSH user must have write access to `CONFIG_DIR`
