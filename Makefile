.PHONY: help install-hooks setup-dev lint test clean scan-secrets update-secrets molecule-test molecule-test-all molecule-converge molecule-verify molecule-destroy

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup-dev: ## Set up development environment
	@echo "Setting up development environment..."
	@command -v pre-commit >/dev/null 2>&1 || { echo >&2 "pre-commit is required but not installed. Please install it first."; exit 1; }
	@command -v detect-secrets >/dev/null 2>&1 || { echo >&2 "detect-secrets is required but not installed. Please install it first."; exit 1; }
	@command -v ansible-lint >/dev/null 2>&1 || { echo >&2 "ansible-lint is required but not installed. Please install it first."; exit 1; }
	@command -v shellcheck >/dev/null 2>&1 || { echo >&2 "shellcheck is required but not installed. Please install it first."; exit 1; }
	pre-commit install
	@echo "Development environment setup complete!"

install-hooks: ## Install pre-commit hooks
	pre-commit install

lint: ## Run all linting checks
	pre-commit run --all-files

lint-ansible: ## Run ansible-lint only
	ansible-lint playbook.yml roles/

lint-shell: ## Run shellcheck only
	find . -name "*.sh" -type f | xargs shellcheck -e SC1091

scan-secrets: ## Scan for secrets
	detect-secrets scan --baseline .secrets.baseline --force-use-all-plugins

update-secrets: ## Update secrets baseline
	detect-secrets scan --baseline .secrets.baseline --force-use-all-plugins --update

audit-secrets: ## Audit secrets baseline
	detect-secrets audit .secrets.baseline

test: ## Run ansible syntax check
	ansible-playbook --syntax-check playbook.yml

clean: ## Clean up temporary files
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete
	find . -name "*.tmp" -delete

install-deps: ## Install development dependencies
	@echo "Installing development dependencies..."
	uv pip install -r requirements-dev.txt
	@echo "Please also install shellcheck using your system package manager:"
	@echo "  Ubuntu/Debian: sudo apt install shellcheck"
	@echo "  macOS: brew install shellcheck"
	@echo "  Arch Linux: sudo pacman -S shellcheck"

molecule-test: ## Run Molecule tests for default scenario
	@echo "Running Molecule tests (default scenario)..."
	cd roles/sysinit && molecule test

molecule-test-all: ## Run all Molecule test scenarios
	@echo "Running all Molecule test scenarios..."
	cd roles/sysinit && molecule test -s default
	cd roles/sysinit && molecule test -s checksum-enforcement
	cd roles/sysinit && molecule test -s idempotency

molecule-converge: ## Run Molecule converge for development
	@echo "Running Molecule converge (for development)..."
	cd roles/sysinit && molecule converge

molecule-verify: ## Run Molecule verify only
	@echo "Running Molecule verify..."
	cd roles/sysinit && molecule verify

molecule-destroy: ## Destroy Molecule test instances
	@echo "Destroying Molecule test instances..."
	cd roles/sysinit && molecule destroy
