# Changelog

## [0.3.0]

### Added

- RPM packaging support (minectl.spec, GitHub Actions CI/CD)
- Automated Docker development environment (dev/)
- Automated test suite (dev/test.sh)
- SSH host key checking disabled for dev/testing environments
- Client-side configuration via `~/.minectl/config`

### Changed

- Config directory now fully client-side configurable via `CONFIG_DIR`
- SSH user is now the config directory owner
- Removed `xargs` dependency for config parsing (uses bash parameter expansion)
- Improved error messages and validation

### Fixed

- SSH connectivity in containerized environments
- Config parsing without external utilities
- Docker Compose compatibility for development

## [0.2.0]

### Added

- Hierarchical configuration system (global + per-server)
- Server-global config directory
- Per-server configuration files
- Configuration reload functionality

### Changed

- Bootstrap script refactored for config-driven deployment
- Server directories isolated from configs

## [0.1.0]

### Added

- Initial release
- Remote server deployment via SSH
- Multiple servers per machine
- Systemd service management
- Basic CLI (start, stop, status, logs, list)
- Configuration validation
