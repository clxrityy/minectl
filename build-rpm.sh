#!/bin/bash

# Quick build script for minectl RPM
# Usage: ./build-rpm.sh

set -euo pipefail

VERSION="0.3.0"
DIST=$(rpm --eval '%{dist}')

echo "Building minectl $VERSION for $DIST..."

# Create build directories
mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

# Create tarball
echo "Creating source tarball..."
tar czf ~/rpmbuild/SOURCES/minectl-${VERSION}.tar.gz \
    --exclude=.git \
    --exclude=.gitignore \
    --exclude='.*.sw*' \
    --transform="s,^,minectl-${VERSION}/," \
    .

# Copy spec file
cp minectl.spec ~/rpmbuild/SPECS/

# Build RPM
echo "Building RPM..."
rpmbuild -ba ~/rpmbuild/SPECS/minectl.spec

# Show result
RPM_PATH="${HOME}/rpmbuild/RPMS/noarch/minectl-${VERSION}-1${DIST}.noarch.rpm"
echo ""
echo "✓ Build complete!"
echo "  Package: $RPM_PATH"
echo ""
echo "Install with:"
echo "  sudo dnf install $RPM_PATH"
