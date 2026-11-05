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
"$mise_bin" prune --tools -y

echo "Updating global tools managed directly by pnpm..."
"$mise_bin" exec -- pnpm update --global --latest
"$mise_bin" exec -- pnpm store prune

echo "Updating tools managed directly by uv..."
"$mise_bin" exec -- uv tool upgrade --all
"$mise_bin" exec -- uv cache prune

echo "Updating Pi extensions..."
"$mise_bin" exec -- pi update --extensions

echo "All updates complete!"
