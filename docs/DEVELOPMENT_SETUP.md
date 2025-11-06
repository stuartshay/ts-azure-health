# Development Environment Setup Guide

This guide will help you set up a complete development environment for the TS Azure Health project.

## Quick Start with VS Code Dev Containers (Recommended)

The fastest way to get started is using VS Code Dev Containers, which provides a fully configured development environment.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/stuartshay/ts-azure-health.git
   cd ts-azure-health
   ```

2. Open in VS Code:

   ```bash
   code .
   ```

3. When prompted, click "Reopen in Container" or use the Command Palette (F1):

   - Type: `Dev Containers: Reopen in Container`

4. Wait for the container to build and initialize (first time takes a few minutes)

5. The development environment is ready! All dependencies are installed and configured.

## What's Included in the Dev Container?

### Tools

- **Node.js 22 (LTS)** - JavaScript/TypeScript runtime
- **Azure CLI** - For Azure resource management
- **GitHub CLI** - For GitHub operations
- **Docker-in-Docker** - Build and run containers within the devcontainer
- **Git** - Latest version

### VS Code Extensions (Auto-installed)

- **TypeScript & JavaScript**: ESLint, Prettier
- **Azure**: Azure Account, App Service, Functions, Resource Groups, Bicep
- **Docker**: Docker extension
- **Git**: GitHub Pull Requests, GitLens
- **Utilities**: IntelliCode, Path IntelliSense, Code Spell Checker, EditorConfig

### Automatic Configuration

- Format on save enabled
- ESLint auto-fix on save
- Consistent tab size (2 spaces)
- TypeScript auto-imports
- Port 3000 forwarded for Next.js

## Manual Setup (Without Dev Containers)

If you prefer to set up the environment manually:

### 1. Install Prerequisites

- **Node.js 22 (LTS)**: [Download](https://nodejs.org/)
- **Azure CLI**: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Git**: [Download](https://git-scm.com/)

### 2. Clone and Install Dependencies

```bash
git clone https://github.com/stuartshay/ts-azure-health.git
cd ts-azure-health/frontend
npm install
```

### 3. Set Up Pre-commit Hooks

Pre-commit hooks help maintain code quality by automatically checking your code before commits.

#### Install pre-commit

```bash
# Using pip
pip install pre-commit

# Or using homebrew (macOS)
brew install pre-commit
```

#### Install the hooks

```bash
cd ts-azure-health  # repository root
pre-commit install
```

See [docs/PRE_COMMIT.md](./PRE_COMMIT.md) for detailed information about pre-commit hooks.

### 4. Configure VS Code (Optional but Recommended)

Install recommended extensions:

- ESLint
- Prettier
- Azure Tools
- Docker
- GitLens

The repository includes VS Code settings in `.vscode/settings.json` for consistent development experience.

## Development Workflow

### Starting the Development Server

```bash
cd frontend
npm run dev
```

The application will be available at http://localhost:3000

### Building the Project

```bash
cd frontend
npm run build
```

### Linting

```bash
cd frontend
npm run lint
```

### Running Pre-commit Hooks Manually

```bash
# From repository root
pre-commit run --all-files
```

### Building Docker Image

```bash
cd frontend
docker build -t ts-azure-health-frontend:latest .
```

## GitHub Codespaces

This repository is also configured for GitHub Codespaces, which provides a cloud-based development environment:

1. Navigate to the repository on GitHub
2. Click the "Code" button
3. Select the "Codespaces" tab
4. Click "Create codespace on [branch]"

The same devcontainer configuration will be used automatically.

## Code Quality Tools

### Pre-commit Hooks

Automatically run before each commit:

- Trailing whitespace removal
- End-of-file fixes
- YAML/JSON validation
- ESLint (TypeScript/JavaScript)
- TypeScript type checking
- Dockerfile linting
- Prettier formatting

### Editor Configuration

- `.editorconfig` - Consistent editor settings across different IDEs
- `.prettierrc` - Code formatting rules
- `.eslintrc.json` - Linting rules (in frontend directory)

## Troubleshooting

### Dev Container Issues

**Problem**: Container fails to build

- **Solution**: Ensure Docker Desktop is running and you have sufficient disk space

**Problem**: Extensions not installed

- **Solution**: Rebuild the container: Command Palette → "Dev Containers: Rebuild Container"

### Pre-commit Issues

**Problem**: Hooks fail to run

- **Solution**: Ensure pre-commit is installed and hooks are installed:
  ```bash
  pip install pre-commit
  pre-commit install
  ```

**Problem**: ESLint or TypeScript hooks fail

- **Solution**: Ensure frontend dependencies are installed:
  ```bash
  cd frontend && npm install
  ```

### Build Issues

**Problem**: "next: not found" error

- **Solution**: Install dependencies:
  ```bash
  cd frontend && npm install
  ```

## Next Steps

1. **Configure Azure Resources**: Follow the [README.md](../README.md) for Azure setup
2. **Set up Environment Variables**: Copy `frontend/.env.example` to `frontend/.env.local`
3. **Review Documentation**: Check `docs/` directory for additional guides
4. **Start Development**: Run `npm run dev` and start building!

## Additional Resources

- [Devcontainer Documentation](.devcontainer/README.md)
- [Pre-commit Hooks Guide](./PRE_COMMIT.md)
- [Main README](../README.md)
- [VS Code Remote - Containers](https://code.visualstudio.com/docs/remote/containers)
- [GitHub Codespaces](https://github.com/features/codespaces)
