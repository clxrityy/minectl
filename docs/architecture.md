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
├── config                    # Global settings (MC_USER, MC_BASE_DIR)
└── servers/
    ├── survival.conf         # Managed server config
    ├── earth-1.conf          # Imported server config
    └── creative.conf         # Managed server config
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

## Imported Server Runtime

Imported servers keep their existing files under `$MC_BASE_DIR/SERVER_NAME`.

`minectl import-server` does **not** replace:

- the server JAR
- `server.properties`
- `eula.txt`
- worlds
- plugins
- existing log files

Instead, `minectl` creates a systemd service and launcher that read the following keys from `jvm.properties`:

- `server_jar`
- `jvm_memory_max`
- `jvm_memory_min`
- `jvm_flags`

This allows an imported server to keep its existing launch configuration while still being managed through `minectl`.

## Logging

For log retrieval, `minectl logs` prefers:

```conf
$MC_BASE_DIR/SERVER_NAME/logs/latest.log
```

If no readable file log is available, it falls back to the server’s systemd journal.

## Deployment Flow

1. **Client setup**: Create `~/.minectl/config` with `CONFIG_DIR`
2. **Init**: `minectl init user@host` creates `$CONFIG_DIR/config` with base host settings
3. **Create**: `minectl create-server user@host --server-name NAME` writes server config and provisions a new server
4. **Import**: `minectl import-server user@host --server-name NAME` adopts an existing server directory without overwriting its files
5. **Manage**: `minectl start`, `stop`, `status`, and `logs` operate through systemd

## Configuration Files

**Global Config** (`$CONFIG_DIR/config`):

- `MC_USER`: Unix user running servers
- `MC_BASE_DIR`: Base directory for all servers

**Managed Server Config** (`$CONFIG_DIR/servers/SERVER_NAME.conf`):

- `ENABLED`: true/false
- `PORT`: Server port
- `MEMORY`: JVM memory (e.g., 4G)
- `JAR_URL`: URL to server JAR

**Imported Server Config** (`$CONFIG_DIR/servers/SERVER_NAME.conf`):

- `ENABLED`: true/false
- `IMPORTED=true`
- `JAVA_BIN`: Remote Java executable path

> [!NOTE]
> For newly created servers, Java version is selected during `create-server` provisioning. For imported servers, runtime settings come from the server's own `jvm.properties`, and minectl stores the resolved Java executable path in the per-server config.

Managed and imported servers have different required config keys. Managed servers require `PORT`, `MEMORY`, and `JAR_URL`; imported servers require `IMPORTED=true` and `JAVA_BIN`.

## Client Config

**File**: `~/.minectl/config`

- `CONFIG_DIR`: Path on remote where server configs live
- `SSH_USER`: SSH user for deployment

## Requirements

- Local: bash, ssh, scp, curl
- Remote: Rocky Linux, sudo access, ~10GB disk per server
- SSH user must have write access to `CONFIG_DIR`
