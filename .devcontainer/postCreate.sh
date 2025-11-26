#!/bin/bash
set -e

echo "🚀 Running post-create setup..."

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend && npm ci

# Install tsx globally for running TypeScript scripts
echo "🚀 Installing tsx globally..."
npm install -g tsx

# Install spec-kit CLI via uv
echo "🔧 Installing spec-kit CLI..."
uv tool install specify-cli

# Setup custom ZSH configuration
echo "🎨 Configuring ZSH prompt..."
cp /workspaces/ts-azure-health/.devcontainer/.zshrc ~/.zshrc


# Install ACE (Azure Cost Estimator)
echo "📦 Installing ACE (Azure Cost Estimator)..."
ACE_VERSION="1.6.4"
ACE_INSTALL_DIR="$HOME/.local/bin/ace"
mkdir -p "$ACE_INSTALL_DIR"

if [ ! -f "$ACE_INSTALL_DIR/azure-cost-estimator" ]; then
    wget -q "https://github.com/TheCloudTheory/arm-estimator/releases/download/${ACE_VERSION}/linux-x64.zip" -O /tmp/ace.zip
    unzip -q /tmp/ace.zip -d "$ACE_INSTALL_DIR"
    chmod +x "$ACE_INSTALL_DIR/azure-cost-estimator"
    rm /tmp/ace.zip
    echo "✅ ACE v${ACE_VERSION} installed successfully"
else
    echo "✅ ACE already installed"
fi

# Add ACE to PATH if not already there
if ! grep -q "ACE_PATH" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin/ace:$PATH"' >> "$HOME/.bashrc"
fi
if ! grep -q "ACE_PATH" "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin/ace:$PATH"' >> "$HOME/.zshrc"
fi
export PATH="$HOME/.local/bin/ace:$PATH"

# Verify ACE installation
if [ -x "$ACE_INSTALL_DIR/azure-cost-estimator" ]; then
    echo "✅ ACE: $("$ACE_INSTALL_DIR/azure-cost-estimator" --version 2>/dev/null || echo 'v1.6.4')"
fi

# Install azure-cost-cli for cost analysis (requires .NET 9 runtime)
echo "📦 Installing azure-cost-cli..."
if command -v dotnet &> /dev/null; then
    # Check if .NET 9 runtime is available
    if ! dotnet --list-runtimes | grep -q "Microsoft.NETCore.App 9."; then
        echo "📦 Installing .NET 9 runtime (required for azure-cost-cli)..."
        wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
        chmod +x /tmp/dotnet-install.sh
        sudo /tmp/dotnet-install.sh --channel 9.0 --runtime dotnet --install-dir /usr/share/dotnet
        rm /tmp/dotnet-install.sh
        echo "✅ .NET 9 runtime installed"
    fi

    if dotnet tool install --global azure-cost-cli --version 0.52.0 2>/dev/null || dotnet tool update --global azure-cost-cli --version 0.52.0 2>/dev/null; then
        echo "✅ azure-cost-cli installed successfully"
        # Ensure dotnet tools are in PATH
        export PATH="$PATH:$HOME/.dotnet/tools"
        if ! grep -q "dotnet tools" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$HOME/.bashrc"
        fi
        if ! grep -q "dotnet tools" "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$HOME/.zshrc"
        fi
        if command -v azure-cost &> /dev/null; then
            echo "✅ azure-cost-cli: $(azure-cost --version 2>/dev/null || echo 'installed')"
        fi
    else
        echo "⚠️  azure-cost-cli installation may have failed"
    fi
else
    echo "⚠️  .NET SDK not found, skipping azure-cost-cli installation"
fi



echo "✅ Post-create setup complete!"
