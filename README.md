# minectl

Remote Minecraft server automation for Rocky Linux (8+). Deploy and manage multiple servers via centralized configuration.

> [!TIP]
>
> See [/test](test/README.md) for local testing with [Docker](https://www.docker.com/).
>
> ```bash
> make test
> ```

- [Quick Install](#quick-install)
- [Local Testing](#local-testing)
- [Setup](#setup)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [License](#license)

---

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

## Local Testing

For local testing on macOS, start Colima first:

```bash
colima start --cpu 4 --memory 8 --disk 40 --runtime docker
docker context use colima
cd test
./test.sh
```

Or, use the Makefile:

```bash
make colima-start
make test
```

## Setup

```bash
# Edit client config
nano ~/.minectl/config
# Set CONFIG_DIR to remote path

# Initialize remote host
minectl init user@10.0.0.5

# Import existing server
minectl import-server user@10.0.0.5 --server-name earth-1

# Create a server
minectl create-server user@10.0.0.5 --server-name survival --port 25565 --memory 4G

# Manage
minectl start user@10.0.0.5 --server-name survival
minectl list user@10.0.0.5
minectl logs user@10.0.0.5 --server-name survival --follow
```

For imported servers, `minectl logs` reads `logs/latest.log` when available and falls back to the systemd journal otherwise.

## Documentation

- [Configuration](docs/configuration.md) — Config structure
- [Usage Guide](docs/usage.md) — Commands and examples
- [Architecture](docs/architecture.md) — Design overview
- [Building](BUILD.md) — Build RPM locally or via GitHub Actions
- [Repository](REPO.md) — Setup DNF repository
- [Test](test/README.md) — Docker test environment
- [Changelog](CHANGELOG.md) — Version history

## Requirements

- Rocky Linux 8+ / RHEL-compatible
- SSH access to target host
- sudo access on target host

## License

[GNU General Public License v3.0 (GPL-3.0)](./LICENSE)
