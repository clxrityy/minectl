# minectl

Remote Minecraft server automation for Rocky Linux. Deploy and manage multiple servers via centralized configuration.

> [!CAUTION]
> **UNDER DEVELOPMENT**
>
> - No stable release available yet
> - **Recommended**: See [Development](dev/README.md) for local testing with Docker.

## Quick Install

```bash
sudo dnf install -y minectl
```

Or use the installation script:

```bash
curl -fsSLO https://clxrityy.github.io/minectl/install.sh
chmod +x install.sh
sudo ./install.sh
```

## Development

For local testing with Docker:

```bash
cd dev
./test.sh
```

## Setup

```bash
# Edit client config
nano ~/.minectl/config
# Set CONFIG_DIR to remote path

# Initialize remote host
minectl init user@10.0.0.5

# Create a server
minectl create-server user@10.0.0.5 --server-name survival --port 25565 --memory 4G

# Manage
minectl start user@10.0.0.5 --server-name survival
minectl list user@10.0.0.5
minectl logs user@10.0.0.5 --server-name survival --follow
```

## Documentation

- [Configuration](docs/configuration.md) — Config structure
- [Usage Guide](docs/usage.md) — Commands and examples
- [Architecture](docs/architecture.md) — Design overview
- [Building](BUILD.md) — Build RPM locally or via GitHub Actions
- [Repository](REPO.md) — Setup DNF repository
- [Development](dev/README.md) — Docker dev environment
- [Changelog](CHANGELOG.md) — Version history

## Requirements

- Rocky Linux 8+ / RHEL-compatible
- SSH access to target host
- sudo access on target host

## License

[GNU General Public License v3.0 (GPL-3.0)](./LICENSE)
