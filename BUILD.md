# Building minectl

## Automated Builds (Recommended)

minectl builds automatically on tag push via GitHub Actions (Rocky Linux 8.6).

### Release Process

```bash
# Tag a release
git tag v0.4.0
git push --tags

# GitHub Actions automatically:
# 1. Builds RPM in Rocky Linux 8.6 container
# 2. Runs rpmlint checks
# 3. Uploads to GitHub Releases
```

RPM will be available at: `https://github.com/yourusername/minectl/releases/tag/vX.Y.Z`

## Manual Local Build

For local development testing:

```bash
# Install dependencies
dnf install -y rpmdevtools rpmlint

# Setup rpmbuild directories
mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

# Create source tarball
tar czf ~/rpmbuild/SOURCES/minectl-0.4.0.tar.gz \
    --exclude=.git \
    --exclude=.gitignore \
    --exclude='.*.sw*' \
    --exclude=.github \
    --transform='s,^,minectl-0.4.0/,' \
    .

# Build RPM
rpmbuild -ba minectl.spec

# Result: ~/rpmbuild/RPMS/noarch/minectl-0.4.0-1.fc39.noarch.rpm
```

## Install Locally

```bash
sudo dnf install -y ~/rpmbuild/RPMS/noarch/minectl-0.4.0-1.fc39.noarch.rpm
minectl version
```

## Using Build Script

```bash
./build-rpm.sh
```

This is a convenience wrapper around the manual process above.

## Spec File

The `minectl.spec` file defines:
- Package name, version, release
- Build requirements
- Installation paths
- Post-install actions
- File ownership and permissions

Update version in `minectl.spec` before building, or it will auto-update during GitHub Actions build.

## Version Management

Version is defined in:
1. `minectl.spec` — RPM version
2. `minectl` CLI — `MINECTL_VERSION` variable
3. GitHub tag — `v0.4.0` format

Keep these in sync.
