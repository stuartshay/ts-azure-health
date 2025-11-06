#!/bin/bash
set -e

echo "🚀 Running post-create setup..."

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend && npm ci

# Install spec-kit CLI via uv
echo "🔧 Installing spec-kit CLI..."
uv tool install specify-cli

# Setup custom ZSH configuration
echo "🎨 Configuring ZSH prompt..."
cp /workspaces/ts-azure-health/.devcontainer/.zshrc ~/.zshrc

echo "✅ Post-create setup complete!"
