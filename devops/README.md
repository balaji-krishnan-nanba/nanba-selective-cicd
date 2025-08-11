# Databricks Selective CI/CD Pipeline

## Overview

This CI/CD pipeline enables selective deployment of Databricks notebooks to different environments (DEV, TEST, PROD) with automatic deployment of shared components. The pipeline is built using GitHub Actions and Databricks Asset Bundles (DAB).

### Key Features

- **Selective Deployment**: Choose specific use cases to deploy
- **Shared Components**: Shared folder is ALWAYS deployed with every deployment
- **Environment Isolation**: Separate workspaces for DEV, TEST, and PROD
- **Automated Validation**: PR-triggered deployments to DEV for validation
- **Manual Control**: TEST and PROD deployments require manual triggering
- **Change Management**: PROD deployments require change ticket and approval

## Architecture

```
nanba-selective-cicd/
├── src/
│   ├── shared/           # Always deployed
│   ├── usecase-1/        # Selectively deployed
│   └── usecase-2/        # Selectively deployed
├── devops/
│   ├── scripts/          # Deployment and validation scripts
│   └── config/           # Environment configurations
├── .github/workflows/    # GitHub Actions workflows
└── databricks.yml        # DAB configuration
```

## Deployment Strategy

### DEV Environment
- **Trigger**: Automatic on PR to main branch
- **Deployment**: ALL use cases + shared folder
- **Purpose**: Validation before merge
- **Cluster**: dev-cluster

### TEST Environment
- **Trigger**: Manual via GitHub Actions
- **Deployment**: Selected use case + shared folder
- **Options**: usecase-1, usecase-2, or all
- **Cluster**: test-cluster

### PROD Environment
- **Trigger**: Manual with approval
- **Deployment**: Selected use case + shared folder
- **Requirements**: Change ticket, approval
- **Cluster**: prod-cluster

## Setup Instructions

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

#### Required Secrets
- `DATABRICKS_HOST_DEV`: DEV workspace URL
- `DATABRICKS_TOKEN_DEV`: DEV access token
- `DATABRICKS_HOST_TEST`: TEST workspace URL
- `DATABRICKS_TOKEN_TEST`: TEST access token
- `DATABRICKS_HOST_PROD`: PROD workspace URL
- `DATABRICKS_TOKEN_PROD`: PROD access token

#### Optional Secrets
None required at this time.

### 2. Workspace Structure

Each environment will have the following structure:
```
/Workspace/Deployments/{environment}/
├── shared/         # Shared notebooks
├── usecase-1/      # Use Case 1 notebooks
└── usecase-2/      # Use Case 2 notebooks
```

### 3. Cluster Configuration

All environments use single-node clusters with:
- **Instance Type**: Standard_DS3_v2
- **Runtime**: Photon 16.4.x-scala2.12
- **Auto-termination**: 10 minutes
- **Mode**: Single Node

## Usage Guide

### Local Development

```bash
# Install dependencies
make setup

# Validate configuration
make validate

# Deploy to DEV (requires env vars)
make deploy-dev

# Deploy to TEST (interactive)
make deploy-test

# Deploy to PROD (interactive with confirmation)
make deploy-prod
```

### GitHub Actions Workflows

#### 1. PR Validation (Automatic)
- Creates PR from `feature/*` to `main`
- Automatically deploys to DEV
- Validates all use cases

#### 2. Deploy to TEST (Manual)
```
Actions → Deploy to TEST → Run workflow
→ Select use case (usecase-1, usecase-2, or all)
→ Deploy
```

#### 3. Deploy to PROD (Manual)
```
Actions → Deploy to PROD → Run workflow
→ Select use case (usecase-1 or usecase-2)
→ Enter change ticket
→ Provide deployment reason
→ Deploy (requires approval)
```

## Deployment Scripts

### deploy.sh
Bash script for selective deployment:
```bash
./devops/scripts/deploy.sh <environment> <use_case>

# Examples:
./devops/scripts/deploy.sh dev all
./devops/scripts/deploy.sh test usecase-1
./devops/scripts/deploy.sh prod usecase-2
```

### validate_deployment.py
Python script for deployment validation:
```bash
python devops/scripts/validate_deployment.py \
  --env <environment> \
  --host <databricks_host> \
  --use-case <use_case>

# Examples:
python devops/scripts/validate_deployment.py --env dev --validate-all
python devops/scripts/validate_deployment.py --env test --use-case usecase-1
python devops/scripts/validate_deployment.py --env prod --smoke-test
```

## Important Notes

### Shared Folder Behavior
- The `src/shared` folder is **ALWAYS** deployed
- It contains common utilities and libraries
- Cannot be excluded from deployments
- Deploy first, before use case folders

### Branching Strategy
- **main**: Protected branch, production-ready code
- **feature/***: Feature branches, create PR to main
- PRs trigger automatic DEV deployment for validation
- Merge to main creates a release tag

### Deployment Order
1. Shared folder (always first)
2. Selected use case folder(s)
3. Bundle resources (clusters, jobs)
4. Validation checks

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```
Error: Databricks authentication failed
```
**Solution**: Verify GitHub secrets are correctly set

#### 2. Workspace Path Not Found
```
Error: Workspace path does not exist
```
**Solution**: Ensure workspace directories are created

#### 3. Cluster Not Found
```
Warning: test-cluster not found
```
**Solution**: Bundle deployment will create clusters automatically

#### 4. Deployment Validation Failed
```
Error: Shared folder not found
```
**Solution**: Check if notebooks exist in src/shared

### Debug Commands

```bash
# Check current configuration
make show-config

# Validate specific environment
make validate-dev
make validate-test
make validate-prod

# Clean temporary files
make clean

# Run linting
make lint
```

## Best Practices

1. **Always test in DEV first** via PR process
2. **Validate in TEST** before PROD deployment
3. **Use change tickets** for PROD deployments
4. **Monitor deployments** using validation scripts
5. **Keep shared components backward compatible**
6. **Document breaking changes** in PR descriptions
7. **Use semantic versioning** for releases

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review workflow logs in GitHub Actions
3. Run validation scripts locally
4. Contact the DevOps team

## License

This project is proprietary and confidential.