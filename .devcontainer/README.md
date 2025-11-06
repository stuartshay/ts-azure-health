# Development Container Configuration

This directory contains the configuration for the development container used with VS Code's Remote - Containers extension or GitHub Codespaces.

## Features

The devcontainer includes:

### Tools
- **Node.js 22 (LTS)**: JavaScript/TypeScript runtime
- **Azure CLI**: For Azure resource management
- **GitHub CLI**: For GitHub operations
- **Docker-in-Docker**: Build and run containers within the devcontainer
- **Git**: Latest version with PPA updates

### VS Code Extensions

#### TypeScript and JavaScript
- ESLint - Code linting
- Prettier - Code formatting

#### Azure Development
- Azure Account
- Azure App Service
- Azure Functions
- Azure Resource Groups
- Bicep - Infrastructure as Code

#### Docker
- Docker extension for container management

#### Git and GitHub
- GitHub Pull Requests and Issues
- GitLens - Enhanced Git capabilities

#### Development Utilities
- TypeScript Next - Latest TypeScript features
- IntelliCode - AI-assisted development
- Path IntelliSense - Autocomplete for file paths
- Live Server - Local development server
- Code Spell Checker - Spell checking for code
- EditorConfig - Consistent coding styles

## Configuration

The devcontainer:
- Runs as the `node` user for security
- Forwards port 3000 for the Next.js development server
- Automatically runs `npm ci` in the frontend directory after container creation
- Disables Next.js telemetry
- Configures editor settings for consistent formatting and linting
- Mounts the Docker socket for Docker-in-Docker functionality

## Usage

### VS Code
1. Install the "Dev Containers" extension
2. Open the repository in VS Code
3. Click "Reopen in Container" when prompted, or use Command Palette (F1) → "Dev Containers: Reopen in Container"

### GitHub Codespaces
The devcontainer configuration is automatically used when opening the repository in GitHub Codespaces.

## Customization

To customize the devcontainer:
- Edit `devcontainer.json` to add/remove features or extensions
- Modify VS Code settings in the `customizations.vscode.settings` section
- Update `postCreateCommand` to change initialization behavior
