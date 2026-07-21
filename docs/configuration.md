# Configuration

## Client Config (`~/.minectl/config`)

Required before any operation:

```conf
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
```

This tells minectl where config files live on the remote host. The SSH user IS the directory owner.

## Server Config Structure

```conf
$CONFIG_DIR/
├── config                    # Global config (created by minectl init)
└── servers/
    ├── survival.conf         # Per-server config (created by minectl create-server)
    └── creative.conf
```

## Global Config (`$CONFIG_DIR/config`)

Created by `minectl init`. Required keys:

```conf
JAVA_VERSION=17
MC_USER=minecraft
MC_BASE_DIR=/opt/minecraft
```

## Per-Server Config (`$CONFIG_DIR/servers/SERVER_NAME.conf`)

Created by `minectl create-server`. Required keys:

```conf
ENABLED=true
PORT=25565
MEMORY=4G
JAR_URL=https://launcher.mojang.com/v1/objects/.../server.jar
```

## Validation

All configs are validated before deployment.

```bash
minectl validate user@host                             # Validate global config
minectl validate user@host --server-name survival      # Validate specific server
```

Validation fails if any required key is missing or if `~/.minectl/config` is not set up.

## How It Works

1. Client specifies `CONFIG_DIR` in `~/.minectl/config`
2. All operations read from `CONFIG_DIR` on remote via SSH
3. Server-side config is authoritative
4. Client cannot modify server config directly (must use minectl commands)
