#!/bin/bash
set -e

echo "🚀 Starting update process..."

# --- MISE ---
echo "📦 Updating mise core and tools..."
mise self-update -y
mise up

# --- UV ---
echo "🐍 Updating uv and tools..."
uv self update
uv tool upgrade --all

# --- PNPM ---
echo "📦 Updating global pnpm packages & approving builds..."
pnpm up -g --latest
pnpm approve-builds --all

# --- PI ---
echo "🤖 Updating Pi plugins..."
pi update --extensions

echo "✅ All updates complete!"
