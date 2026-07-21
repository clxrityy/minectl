#!/bin/bash
# Installation script for minectl
# Usage: ./install.sh [--prefix /usr/local]

PREFIX="${1:---prefix}"
PREFIX_PATH="${2:---usr/local}"

if [[ "$PREFIX" != "--prefix" ]]; then
    PREFIX_PATH="$PREFIX"
fi

INSTALL_DIR="$PREFIX_PATH/bin"

mkdir -p "$INSTALL_DIR"
cp minectl "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/minectl"

echo "✓ minectl installed to $INSTALL_DIR/minectl"
echo "✓ Add to PATH or run: $INSTALL_DIR/minectl --help"
