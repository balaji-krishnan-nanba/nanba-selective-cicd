# Makefile for Databricks Selective CI/CD Pipeline
# Usage: make <target>

.PHONY: help validate deploy-dev deploy-test deploy-prod clean setup test lint

# Default target
help:
	@echo "Databricks Selective CI/CD Pipeline"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@echo "  help           - Show this help message"
	@echo "  setup          - Install required dependencies"
	@echo "  validate       - Validate bundle configuration"
	@echo "  deploy-dev     - Deploy all use cases to DEV"
	@echo "  deploy-test    - Deploy to TEST (interactive)"
	@echo "  deploy-prod    - Deploy to PROD (interactive)"
	@echo "  test-local     - Run local tests"
	@echo "  lint           - Run linting checks"
	@echo "  clean          - Clean temporary files"
	@echo ""
	@echo "Environment variables required:"
	@echo "  DATABRICKS_HOST_DEV    - DEV workspace URL"
	@echo "  DATABRICKS_TOKEN_DEV   - DEV access token"
	@echo "  DATABRICKS_HOST_TEST   - TEST workspace URL"
	@echo "  DATABRICKS_TOKEN_TEST  - TEST access token"
	@echo "  DATABRICKS_HOST_PROD   - PROD workspace URL"
	@echo "  DATABRICKS_TOKEN_PROD  - PROD access token"

# Setup dependencies
setup:
	@echo "Setting up dependencies..."
	@echo "Installing Databricks CLI..."
	@curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
	@echo "Installing Python dependencies..."
	@pip install --upgrade pip
	@pip install requests pytest black flake8 mypy
	@echo "✅ Setup complete"

# Validate bundle configuration
validate:
	@echo "Validating Databricks bundle configuration..."
	@databricks bundle validate -t dev || (echo "❌ Validation failed" && exit 1)
	@echo "✅ Bundle configuration is valid"

# Deploy to DEV (all use cases)
deploy-dev:
	@echo "================================================"
	@echo "Deploying to DEV environment"
	@echo "================================================"
	@if [ -z "$(DATABRICKS_HOST_DEV)" ] || [ -z "$(DATABRICKS_TOKEN_DEV)" ]; then \
		echo "❌ Error: DATABRICKS_HOST_DEV and DATABRICKS_TOKEN_DEV must be set"; \
		exit 1; \
	fi
	@export DATABRICKS_HOST=$(DATABRICKS_HOST_DEV) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_DEV) && \
	echo "Deploying bundle to DEV..." && \
	databricks bundle deploy -t dev --auto-approve && \
	echo "Deploying notebooks..." && \
	chmod +x devops/scripts/deploy.sh && \
	./devops/scripts/deploy.sh dev all
	@echo "✅ DEV deployment complete"

# Deploy to TEST (interactive)
deploy-test:
	@echo "================================================"
	@echo "Deploy to TEST environment"
	@echo "================================================"
	@if [ -z "$(DATABRICKS_HOST_TEST)" ] || [ -z "$(DATABRICKS_TOKEN_TEST)" ]; then \
		echo "❌ Error: DATABRICKS_HOST_TEST and DATABRICKS_TOKEN_TEST must be set"; \
		exit 1; \
	fi
	@echo "Select use case to deploy:"
	@echo "  1) usecase-1"
	@echo "  2) usecase-2"
	@echo "  3) all"
	@read -p "Enter choice (1-3): " choice; \
	case $$choice in \
		1) use_case="usecase-1" ;; \
		2) use_case="usecase-2" ;; \
		3) use_case="all" ;; \
		*) echo "Invalid choice" && exit 1 ;; \
	esac; \
	export DATABRICKS_HOST=$(DATABRICKS_HOST_TEST) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_TEST) && \
	echo "Deploying $$use_case to TEST..." && \
	databricks bundle deploy -t test --auto-approve && \
	chmod +x devops/scripts/deploy.sh && \
	./devops/scripts/deploy.sh test $$use_case
	@echo "✅ TEST deployment complete"

# Deploy to PROD (interactive with confirmation)
deploy-prod:
	@echo "================================================"
	@echo "⚠️  PRODUCTION DEPLOYMENT"
	@echo "================================================"
	@if [ -z "$(DATABRICKS_HOST_PROD)" ] || [ -z "$(DATABRICKS_TOKEN_PROD)" ]; then \
		echo "❌ Error: DATABRICKS_HOST_PROD and DATABRICKS_TOKEN_PROD must be set"; \
		exit 1; \
	fi
	@echo "Select use case to deploy:"
	@echo "  1) usecase-1"
	@echo "  2) usecase-2"
	@read -p "Enter choice (1-2): " choice; \
	case $$choice in \
		1) use_case="usecase-1" ;; \
		2) use_case="usecase-2" ;; \
		*) echo "Invalid choice" && exit 1 ;; \
	esac; \
	read -p "Enter change ticket number: " ticket; \
	if [ -z "$$ticket" ]; then \
		echo "❌ Change ticket is required for PROD deployment"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "You are about to deploy $$use_case to PRODUCTION"; \
	echo "Change ticket: $$ticket"; \
	read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "Deployment cancelled"; \
		exit 0; \
	fi; \
	export DATABRICKS_HOST=$(DATABRICKS_HOST_PROD) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_PROD) && \
	echo "Deploying $$use_case to PROD..." && \
	databricks bundle deploy -t prod --auto-approve && \
	chmod +x devops/scripts/deploy.sh && \
	./devops/scripts/deploy.sh prod $$use_case
	@echo "✅ PROD deployment complete"
	@echo "Change ticket: $$ticket"

# Run local tests
test-local:
	@echo "Running local tests..."
	@python -m pytest tests/ -v || true
	@echo "Running validation script..."
	@python devops/scripts/validate_deployment.py --env dev --smoke-test || true
	@echo "✅ Local tests complete"

# Lint Python code
lint:
	@echo "Running linting checks..."
	@echo "Checking Python files with flake8..."
	@flake8 devops/scripts/ --max-line-length=120 --ignore=E203,W503 || true
	@echo "Checking Python files with black..."
	@black --check devops/scripts/ || true
	@echo "✅ Linting complete"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@rm -rf .databricks/
	@rm -rf .bundle/
	@rm -rf __pycache__/
	@rm -rf .pytest_cache/
	@rm -rf *.pyc
	@rm -rf .coverage
	@rm -rf htmlcov/
	@rm -rf .DS_Store
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name ".DS_Store" -delete 2>/dev/null || true
	@echo "✅ Clean complete"

# Validate deployment for specific environment
validate-dev:
	@export DATABRICKS_HOST=$(DATABRICKS_HOST_DEV) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_DEV) && \
	python devops/scripts/validate_deployment.py --env dev --validate-all

validate-test:
	@export DATABRICKS_HOST=$(DATABRICKS_HOST_TEST) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_TEST) && \
	python devops/scripts/validate_deployment.py --env test --validate-all

validate-prod:
	@export DATABRICKS_HOST=$(DATABRICKS_HOST_PROD) && \
	export DATABRICKS_TOKEN=$(DATABRICKS_TOKEN_PROD) && \
	python devops/scripts/validate_deployment.py --env prod --validate-all

# Show current configuration
show-config:
	@echo "Current Configuration:"
	@echo "====================="
	@echo "DEV Host:  $${DATABRICKS_HOST_DEV:-NOT SET}"
	@echo "TEST Host: $${DATABRICKS_HOST_TEST:-NOT SET}"
	@echo "PROD Host: $${DATABRICKS_HOST_PROD:-NOT SET}"
	@echo ""
	@echo "Tokens configured:"
	@[ -n "$${DATABRICKS_TOKEN_DEV}" ] && echo "  ✅ DEV token set" || echo "  ❌ DEV token not set"
	@[ -n "$${DATABRICKS_TOKEN_TEST}" ] && echo "  ✅ TEST token set" || echo "  ❌ TEST token not set"
	@[ -n "$${DATABRICKS_TOKEN_PROD}" ] && echo "  ✅ PROD token set" || echo "  ❌ PROD token not set"

# Install pre-commit hooks (optional)
install-hooks:
	@echo "Installing pre-commit hooks..."
	@pip install pre-commit
	@pre-commit install
	@echo "✅ Pre-commit hooks installed"