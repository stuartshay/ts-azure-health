#!/bin/bash
set -e

echo "🚀 Running post-create setup..."

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend && npm ci

# Install spec-kit CLI via uv
echo "🔧 Installing spec-kit CLI..."
uv tool install specify-cli

echo "✅ Post-create setup complete!"
