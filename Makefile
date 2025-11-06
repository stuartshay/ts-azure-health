.PHONY: help install dev build start clean lint lint-fix format format-check type-check test docker-build docker-up docker-down bicep-build bicep-deploy azure-login git-status

# Default target - show help
help:
	@echo "Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  make install        - Install frontend dependencies"
	@echo "  make dev            - Start Next.js development server"
	@echo "  make build          - Build Next.js application for production"
	@echo "  make start          - Start Next.js production server"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint           - Run ESLint"
	@echo "  make lint-fix       - Run ESLint and auto-fix issues"
	@echo "  make format         - Format code with Prettier"
	@echo "  make format-check   - Check code formatting"
	@echo "  make type-check     - Run TypeScript type checking"
	@echo "  make qa             - Run all quality checks (lint, format, type-check)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Remove build artifacts and dependencies"
	@echo "  make clean-build    - Remove only build artifacts"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build   - Build Docker image for frontend"
	@echo "  make docker-run     - Run frontend in Docker container"
	@echo "  make docker-stop    - Stop running Docker containers"
	@echo ""
	@echo "Azure & Infrastructure:"
	@echo "  make bicep-build    - Build Bicep infrastructure"
	@echo "  make bicep-lint     - Lint Bicep files"
	@echo "  make azure-login    - Login to Azure CLI"
	@echo ""
	@echo "Git:"
	@echo "  make git-status     - Show git status"
	@echo "  make git-clean      - Clean untracked files (dry-run)"
	@echo ""

# Development
install:
	@echo "Installing dependencies..."
	cd frontend && npm ci

dev:
	@echo "Starting development server..."
	cd frontend && npm run dev

build:
	@echo "Building application..."
	cd frontend && npm run build

start:
	@echo "Starting production server..."
	cd frontend && npm run start

# Code Quality
lint:
	@echo "Running ESLint..."
	cd frontend && npm run lint

lint-fix:
	@echo "Running ESLint with auto-fix..."
	cd frontend && npm run lint:fix

format:
	@echo "Formatting code with Prettier..."
	cd frontend && npm run format

format-check:
	@echo "Checking code formatting..."
	cd frontend && npm run format:check

type-check:
	@echo "Running TypeScript type checking..."
	cd frontend && npm run type-check

qa: lint format-check type-check
	@echo "✓ All quality checks passed!"

# Cleanup
clean:
	@echo "Cleaning build artifacts and dependencies..."
	rm -rf frontend/node_modules
	rm -rf frontend/.next
	rm -rf frontend/out
	@echo "✓ Clean complete!"

clean-build:
	@echo "Cleaning build artifacts..."
	rm -rf frontend/.next
	rm -rf frontend/out
	@echo "✓ Build artifacts removed!"

# Docker
docker-build:
	@echo "Building Docker image..."
	cd frontend && docker build -t ts-azure-health-frontend .

docker-run:
	@echo "Running Docker container..."
	docker run -p 3000:3000 --name ts-azure-health-frontend ts-azure-health-frontend

docker-stop:
	@echo "Stopping Docker containers..."
	docker stop ts-azure-health-frontend || true
	docker rm ts-azure-health-frontend || true

# Azure & Infrastructure
bicep-build:
	@echo "Building Bicep templates..."
	az bicep build --file infrastructure/main.bicep

bicep-lint:
	@echo "Linting Bicep files..."
	az bicep lint --file infrastructure/main.bicep

azure-login:
	@echo "Logging into Azure..."
	az login

# Git
git-status:
	@git status

git-clean:
	@echo "Showing files that would be removed (dry-run)..."
	@git clean -n -d
