# minectl DNF Repository

This repository hosts RPM packages for minectl.

## Installation

Add the repository to your system:

```bash
sudo dnf install -y https://github.com/clxrityy/minectl/releases/download/v0.3.0/minectl-0.3.0-1.fc39.noarch.rpm
```

Or add the repo permanently:

```bash
sudo dnf config-manager --add-repo https://clxrityy.github.io/minectl/repo/
sudo dnf install -y minectl
```

## Repository Structure

```bash
repo/
├── repodata/
│   ├── repomd.xml
│   ├── primary.xml.gz
│   └── filelists.xml.gz
└── Packages/
    └── minectl-*.noarch.rpm
```

## Building and Publishing

See [BUILD.md](../BUILD.md) for build instructions.

To publish:

1. Build RPM locally
2. Upload to GitHub Releases
3. Regenerate repodata with `createrepo`
4. Push changes

### Example

```bash
# Build
./build-rpm.sh

# Create repo directory
mkdir -p repo/Packages
cp ~/rpmbuild/RPMS/noarch/*.rpm repo/Packages/

# Generate metadata
createrepo repo/

# Commit and push
git add repo/
git commit -m "Update minectl RPM to v0.3.0"
git push
```

## For Repository Maintainers

Users can then install from your repo:

```bash
sudo dnf config-manager --add-repo https://clxrityy.github.io/minectl/repo/
sudo dnf makecache
sudo dnf install -y minectl
```
