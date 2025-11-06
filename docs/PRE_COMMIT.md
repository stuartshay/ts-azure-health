# Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) to maintain code quality and consistency.

## Installation

### Install pre-commit

```bash
# Using pip
pip install pre-commit

# Using homebrew (macOS)
brew install pre-commit

# Using conda
conda install -c conda-forge pre-commit
```

### Install the git hooks

```bash
# From the repository root
pre-commit install
```

This will install the pre-commit hooks into your local git repository. The hooks will run automatically before each commit.

## Usage

### Automatic execution
Once installed, the hooks will run automatically before each commit:

```bash
git commit -m "Your commit message"
```

### Manual execution
To run the hooks manually on all files:

```bash
pre-commit run --all-files
```

To run on specific files:

```bash
pre-commit run --files path/to/file1 path/to/file2
```

### Skip hooks (not recommended)
If you need to commit without running hooks:

```bash
git commit --no-verify -m "Your commit message"
```

## Configured Hooks

### General File Quality
- **trailing-whitespace**: Removes trailing whitespace (except in Markdown)
- **end-of-file-fixer**: Ensures files end with a newline
- **check-yaml**: Validates YAML syntax
- **check-json**: Validates JSON syntax
- **check-added-large-files**: Prevents committing large files (>1MB)
- **check-merge-conflict**: Detects merge conflict markers
- **detect-private-key**: Prevents committing private keys
- **mixed-line-ending**: Ensures consistent line endings (LF)

### TypeScript/JavaScript
- **eslint**: Lints TypeScript and JavaScript files in the frontend directory
- **typescript-check**: Type-checks TypeScript files without emitting output

### Dockerfile
- **hadolint-docker**: Lints Dockerfiles for best practices

### Formatting
- **prettier**: Formats JSON, YAML, and Markdown files

## Troubleshooting

### Hook failures
If a hook fails:
1. Review the error message to understand what needs to be fixed
2. Make the necessary changes
3. Stage the changes: `git add <files>`
4. Commit again: `git commit -m "Your message"`

### Updating hooks
To update hooks to the latest versions:

```bash
pre-commit autoupdate
```

### Clean cache
If you encounter issues with hook execution:

```bash
pre-commit clean
pre-commit install --install-hooks
```

## IDE Integration

### VS Code
The devcontainer configuration includes settings for automatic formatting on save, which complements the pre-commit hooks:
- ESLint auto-fix on save
- Prettier formatting on save

This means most issues will be fixed automatically as you work, and the pre-commit hooks serve as a final safety check.

## CI/CD Integration

Consider adding pre-commit to your CI/CD pipeline to ensure code quality:

```yaml
# Example GitHub Actions workflow
- name: Run pre-commit
  run: |
    pip install pre-commit
    pre-commit run --all-files
```
