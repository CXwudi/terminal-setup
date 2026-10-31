#!/bin/bash
# Update global tools from the user's home, outside project mise configurations.
set -euo pipefail

cd "$HOME"
mise_bin="$HOME/.local/bin/mise"
if [[ ! -x "$mise_bin" ]]; then
  mise_bin="$(command -v mise)"
fi

echo "Starting update process..."
echo "Updating mise and its managed tools..."
"$mise_bin" self-update -y
"$mise_bin" upgrade

echo "Updating tools managed directly by uv..."
"$mise_bin" exec -- uv tool upgrade --all

echo "Updating Pi extensions..."
"$mise_bin" exec -- pi update --extensions

echo "All updates complete!"
