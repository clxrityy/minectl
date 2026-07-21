# Changelog

## [0.3.0]

### Changed

- Config directory now fully client-side configurable via `~/.minectl/config`
- Moved from hardcoded `/home/minecraft-servers/` to dynamic `CONFIG_DIR`
- SSH user is now the config directory owner
- Server-side config is fully authoritative

### Added

- RPM packaging support (minectl.spec)
- Build instructions (BUILD.md)
- Automatic config template installation

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
