#!/usr/bin/env bash
# Installer script for Omarchy Display Manager plugin
set -e

PLUGIN_ID="azterisk.display-manager"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
TARGET_DIR="$PLUGINS_DIR/$PLUGIN_ID"
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
REPO_URL="https://github.com/Azteriisk/omarchy-display-manager.git"

echo "==> Installing Omarchy Display Manager plugin ($PLUGIN_ID)..."

# Ensure plugins directory exists
mkdir -p "$PLUGINS_DIR"

# If script is run from a cloned folder outside plugins dir, copy files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
  cp -a "$SCRIPT_DIR/manifest.json" "$SCRIPT_DIR/Panel.qml" "$SCRIPT_DIR/Model.js" "$SCRIPT_DIR/README.md" "$TARGET_DIR/"
fi

# Enable plugin via omarchy CLI if available
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable "$PLUGIN_ID" 2>/dev/null || true
  omarchy restart shell 2>/dev/null || true
else
  # Fallback JSON update
  if [ -f "$SHELL_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq 'if (.bar.layout.right | map(.id == "azterisk.display-manager") | any) then . else .bar.layout.right += [{"id":"azterisk.display-manager"}] end' "$SHELL_CONFIG" > "$tmp" && mv "$tmp" "$SHELL_CONFIG"
  fi
fi

echo "==> Omarchy Display Manager installed and activated successfully!"
echo "==> The Display icon is now visible in your top navbar."
