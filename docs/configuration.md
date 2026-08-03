# Configuration

## Client Config (`~/.minectl/config`)

Required before any operation:

```conf
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
```

This tells `minectl` where configuration files live on the remote host. The SSH user is the owner of that configuration directory or must at least have access to it.

## Server Config Structure

```conf
$CONFIG_DIR/
├── config                    # Global config created by `minectl init`
└── servers/
    ├── survival.conf         # Managed server config
    └── earth-1.conf          # Imported server config
```

## Global Config (`$CONFIG_DIR/config`)

Created by `minectl init`. Required keys:

```conf
MC_USER=minecraft
MC_BASE_DIR=/opt/minecraft
```

> [!NOTE]
> `minectl init` sets base host configuration only. Java version is not part of global config. For newly created servers, Java version may be specified at creation time with `--java-version`. Imported servers use their existing `jvm.properties` and a per-server `JAVA_BIN`.

## Managed Server Config (`$CONFIG_DIR/servers/SERVER_NAME.conf`)

Created by `minectl create-server`. Required keys:

```conf
ENABLED=true
PORT=25565
MEMORY=4G
JAR_URL=https://launcher.mojang.com/v1/objects/.../server.jar
```

These settings are used for servers that `minectl` provisions itself.

## Imported Server Config (`$CONFIG_DIR/servers/SERVER_NAME.conf`)

Created by `minectl import-server`. Required keys:

```conf
ENABLED=true
IMPORTED=true
JAVA_BIN=/usr/lib/jvm/jdk-25/bin/java
```

Imported servers keep their own runtime settings in:

```conf
$MC_BASE_DIR/SERVER_NAME/jvm.properties
```

`minectl` reads the following keys from `jvm.properties` when generating the launcher for imported servers:

- `server_jar`
- `jvm_memory_max`
- `jvm_memory_min`
- `jvm_flags`

## Validation

All configs are validated before deployment or management operations.

```bash
minectl validate user@host
minectl validate user@host --server-name survival
minectl validate user@host --server-name earth-1
```

Validation rules differ by config type:

- **Global config** requires:
  - `MC_USER`
  - `MC_BASE_DIR`

- **Managed server config** requires:
  - `ENABLED`
  - `PORT`
  - `MEMORY`
  - `JAR_URL`

- **Imported server config** requires:
  - `ENABLED`
  - `IMPORTED=true`
  - `JAVA_BIN`

Validation fails if required keys are missing or if `~/.minectl/config` is not set up locally.

## How It Works

1. Client config defines `CONFIG_DIR` in `~/.minectl/config`
2. `minectl init` creates base host config on the remote machine
3. `minectl create-server` creates managed per-server config and provisions a new server
4. `minectl import-server` creates imported per-server config and adopts an existing server
5. All operations read server-side config from `CONFIG_DIR` via SSH
