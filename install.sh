#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (or with sudo)."
    exit 1
fi

echo "Installing minectl repository..."

command -v dnf >/dev/null || {
    echo "This installer requires DNF."
    exit 1
}

curl -fsSL \
    https://clxrityy.github.io/minectl/minectl.repo \
    -o /etc/yum.repos.d/minectl.repo

dnf makecache
dnf install -y minectl

echo
echo "minectl installed successfully."
echo "Run: minectl --help"
