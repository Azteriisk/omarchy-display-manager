#!/usr/bin/env bash
# Uninstaller script for Omarchy Display Manager plugin
set -e

PLUGIN_ID="azterisk.display-manager"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$PLUGIN_ID"
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"

echo "==> Uninstalling Omarchy Display Manager plugin ($PLUGIN_ID)..."

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
fi

if [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
fi

if [ -f "$SHELL_CONFIG" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq '.bar.layout.right |= map(select(.id != "azterisk.display-manager"))' "$SHELL_CONFIG" > "$tmp" && mv "$tmp" "$SHELL_CONFIG"
fi

if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell 2>/dev/null || true
fi

echo "==> Omarchy Display Manager uninstalled successfully."
