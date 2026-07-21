# Build and Install minectl as RPM

## Prerequisites

```bash
dnf install -y rpmdevtools
```

## Build Package

```bash
# Clone repo
git clone https://github.com/clxrityy/minectl.git
cd minectl

# Create tarball
mkdir -p ~/rpmbuild/SOURCES
tar czf ~/rpmbuild/SOURCES/minectl-0.3.0.tar.gz \
    --exclude=.git \
    --exclude=.gitignore \
    --transform='s,^,minectl-0.3.0/,' \
    --exclude='minectl-0.3.0' \
    .

# Build RPM
rpmbuild -ba minectl.spec

# Package will be at: ~/rpmbuild/RPMS/noarch/minectl-0.3.0-1.fc*.noarch.rpm
```

## Install Locally

```bash
sudo dnf install -y ~/rpmbuild/RPMS/noarch/minectl-0.3.0-1.fc*.noarch.rpm
```

## Verify Installation

```bash
minectl version
# Should output: minectl v0.3.0
```

## Setup Client Config

```bash
# Edit ~/.minectl/config
nano ~/.minectl/config

# Set CONFIG_DIR to remote path
# Example: CONFIG_DIR=/home/minecraft-servers
```

## Use minectl

```bash
minectl init user@host
minectl create-server user@host --server-name survival
```

## Publish to Repository

To publish to a private/public RPM repository, upload the built RPM from:

```bash
~/rpmbuild/RPMS/noarch/minectl-0.3.0-1.fc*.noarch.rpm
```

Then users can install with:

```bash
dnf install minectl
```
