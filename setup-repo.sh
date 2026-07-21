#!/bin/bash

# Setup minectl DNF repository
# Run on a web server to host the repo

set -euo pipefail

REPO_DIR="repo"

echo "Setting up minectl repository..."

# Create structure
mkdir -p "$REPO_DIR/Packages"

# Copy RPMs
echo "Copying RPMs to $REPO_DIR/Packages..."
cp ~/rpmbuild/RPMS/noarch/*.rpm "$REPO_DIR/Packages/" 2>/dev/null || echo "No RPMs found"

# Generate repodata
echo "Generating repository metadata..."
if command -v createrepo &> /dev/null; then
    createrepo "$REPO_DIR"
    echo "✓ Repository ready at $REPO_DIR/"
    echo ""
    echo "To serve with HTTP:"
    echo "  cd $REPO_DIR && python3 -m http.server 8080"
    echo ""
    echo "Users can add with:"
    echo "  sudo dnf config-manager --add-repo http://your-server:8080/"
    echo "  sudo dnf install minectl"
else
    echo "✗ createrepo not found. Install with: dnf install -y createrepo_c"
fi
