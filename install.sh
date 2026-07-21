#!/bin/bash

# Install minectl from repo
# Usage: curl -fsSL https://yourusername.github.io/minectl/install.sh | bash

set -euo pipefail

REPO_URL="${REPO_URL:-https://yourusername.github.io/minectl/repo/}"

echo "Installing minectl from $REPO_URL"

# Add repo
sudo dnf config-manager --add-repo "$REPO_URL"

# Install
sudo dnf install -y minectl

# Setup config
if [[ ! -f ~/.minectl/config ]]; then
    mkdir -p ~/.minectl
    cp /etc/skel/.minectl/config.template ~/.minectl/config
    echo ""
    echo "✓ minectl installed!"
    echo "✓ Edit ~/.minectl/config to set CONFIG_DIR"
    echo ""
    echo "Next steps:"
    echo "  nano ~/.minectl/config"
    echo "  minectl init user@host"
else
    echo "✓ minectl installed!"
fi
