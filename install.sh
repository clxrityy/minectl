#!/bin/bash
# Install minectl on Rocky Linux
# Usage: sudo bash -c "$(curl -fsSL https://clxrityy.github.io/minectl/install.sh)"
 
set -euo pipefail
 
REPO_URL="https://clxrityy.github.io/minectl/minectl.repo"
REPO_FILE="/etc/yum.repos.d/minectl.repo"
 
if [[ $EUID -ne 0 ]]; then
    echo "error: run this script as root" >&2
    echo ""
    echo "  sudo bash -c \"\$(curl -fsSL https://clxrityy.github.io/minectl/install.sh)\""
    exit 1
fi
 
echo "==> Adding minectl repository..."
curl -fsSL "$REPO_URL" -o "$REPO_FILE"
 
echo "==> Installing minectl..."
dnf install -y minectl
 
echo ""
echo "Done. Run 'minectl --help' to get started."
 