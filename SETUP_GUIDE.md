# GitHub Environments Setup Guide

## Overview

This pipeline uses GitHub Environments to manage configuration and secrets securely. Each environment (development, test, production) has its own variables and secrets.

## Environment Configuration

### Environments Created

The following environments are configured in the repository:

| Environment | Purpose | Approval Required |
|------------|---------|-------------------|
| `development` | Auto-deploys on PR creation for validation | No |
| `test` | Manual deployment for integration testing | No |
| `production` | Manual deployment for production releases | Yes |

### Environment Variables and Secrets

Each environment has:
- **Variable**: `DATABRICKS_HOST` - The Azure Databricks workspace URL
- **Secret**: `DATABRICKS_TOKEN` - The access token for authentication

## How It Works

### 1. Development Environment
- **Trigger**: Automatically when PR is created to `main` branch
- **Purpose**: Validate changes before merge
- **Deployment**: All use cases + shared folder

### 2. Test Environment  
- **Trigger**: Manual via GitHub Actions
- **Purpose**: Integration testing
- **Deployment**: Selected use case + shared folder (always)

### 3. Production Environment
- **Trigger**: Manual via GitHub Actions with approval
- **Purpose**: Production releases
- **Requirements**: Change ticket, deployment reason
- **Deployment**: Selected use case + shared folder (always)

## Testing the Pipeline

### Step 1: Create a Pull Request
```bash
# From your feature branch
git push origin feature/selective-cicd-setup

# Create PR on GitHub
# This will automatically trigger deployment to development environment
```

### Step 2: Test Deployment (After Merge)
1. Go to **Actions** tab in GitHub
2. Select **Deploy to TEST** workflow
3. Click **Run workflow**
4. Select use case and deploy

### Step 3: Production Deployment
1. Go to **Actions** tab
2. Select **Deploy to PROD** workflow  
3. Click **Run workflow**
4. Enter required information:
   - Use case selection
   - Change ticket number
   - Deployment reason
5. Wait for approval (if configured)
6. Deployment proceeds after approval

## Verify Your Setup

### Check Environments
1. Go to: https://github.com/balaji-krishnan-nanba/nanba-selective-cicd/settings/environments
2. Verify all three environments exist
3. Click each environment to verify:
   - `DATABRICKS_HOST` is set as variable
   - `DATABRICKS_TOKEN` is set as secret

### Check Workflows
1. Go to **Actions** tab
2. You should see these workflows:
   - PR Validation and Deploy to DEV
   - Deploy to TEST
   - Deploy to PROD
   - Post-Merge Actions

## Local Development

For local testing and deployment:

```bash
# Set environment variables
export DATABRICKS_HOST=<your-workspace-url>
export DATABRICKS_TOKEN=<your-token>

# Validate configuration
make validate

# Deploy to environment
make deploy-dev   # Requires DEV credentials
make deploy-test  # Interactive, requires TEST credentials  
make deploy-prod  # Interactive with confirmation, requires PROD credentials
```

## Troubleshooting

### Common Issues

1. **Workflow fails with authentication error**
   - Verify `DATABRICKS_TOKEN` secret is set correctly in the environment
   - Check token hasn't expired
   - Ensure token has necessary permissions

2. **Environment not found error**
   - Verify environment names match exactly: `development`, `test`, `production`
   - Check workflows are using correct environment names

3. **Cannot access variables/secrets**
   - Ensure you're setting them at environment level, not repository level
   - Variables are for non-sensitive data (URLs)
   - Secrets are for sensitive data (tokens)

4. **Production deployment not requiring approval**
   - Check protection rules in production environment settings
   - Add required reviewers if needed

## Security Best Practices

1. **Token Management**
   - Rotate tokens every 90 days
   - Use service principals instead of personal tokens
   - Grant minimal required permissions

2. **Environment Protection**
   - Production should always require approval
   - Consider adding deployment branch restrictions
   - Enable deployment history retention

3. **Monitoring**
   - Regularly check Actions tab for failed deployments
   - Review deployment history in each environment
   - Set up notifications for deployment failures

## Support

For assistance:
- **GitHub Actions logs**: Check Actions tab for detailed error messages
- **Environment settings**: Settings → Environments
- **Databricks connectivity**: Test with `databricks workspace ls /` locally
- **Repository issues**: Create an issue in the repository