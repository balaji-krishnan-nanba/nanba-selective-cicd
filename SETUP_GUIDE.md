# GitHub Environments and Secrets Setup Guide

## Overview

This pipeline uses GitHub Environments to manage secrets securely. Each environment (development, test, production) has its own set of secrets.

## Setup Methods

### Method 1: Automated Setup (Recommended)

Run the provided script to automatically create environments and set secrets:

```bash
# Make sure you have GitHub CLI installed
gh auth login

# Run the setup script
./setup-github-environments.sh

# Enter your Azure Databricks details when prompted
```

### Method 2: Manual Setup via GitHub UI

#### Step 1: Create Environments

1. Go to your repository: https://github.com/balaji-krishnan-nanba/nanba-selective-cicd
2. Click on **Settings** → **Environments**
3. Create three environments:
   - `development`
   - `test`
   - `production`

#### Step 2: Configure Each Environment

For **each environment**, add these secrets:

##### Development Environment
1. Click on `development` environment
2. Add secrets:
   - `DATABRICKS_HOST`: Your DEV workspace URL
   - `DATABRICKS_TOKEN`: Your DEV access token

##### Test Environment
1. Click on `test` environment
2. Add secrets:
   - `DATABRICKS_HOST`: Your TEST workspace URL
   - `DATABRICKS_TOKEN`: Your TEST access token

##### Production Environment
1. Click on `production` environment
2. Add secrets:
   - `DATABRICKS_HOST`: Your PROD workspace URL
   - `DATABRICKS_TOKEN`: Your PROD access token
3. Configure protection rules:
   - Enable **Required reviewers**
   - Add yourself or team members as reviewers
   - Enable **Prevent self-review** if desired

## Environment-Specific Configuration

### Development
- **Auto-deploys** on PR creation
- No approval required
- Used for validation before merge

### Test
- **Manual deployment** via GitHub Actions
- No approval required
- Used for integration testing

### Production
- **Manual deployment** via GitHub Actions
- **Requires approval** from designated reviewers
- Requires change ticket number
- Creates backup before deployment

## Benefits of Using Environments

1. **Security**: Secrets are scoped to specific environments
2. **Audit Trail**: All deployments are logged with who approved
3. **Protection Rules**: Production requires approval
4. **Visibility**: Clear view of what's deployed where
5. **Compliance**: Better for SOC2/ISO requirements

## Verify Setup

After setting up environments:

1. Go to **Settings** → **Environments**
2. You should see all three environments
3. Click each to verify secrets are configured
4. For production, verify protection rules are enabled

## Testing the Pipeline

1. **Create a Pull Request**
   - Push changes to `feature/selective-cicd-setup`
   - Create PR to `main`
   - Should trigger automatic deployment to `development`

2. **Test Deployment**
   - After merge, go to **Actions** tab
   - Run "Deploy to TEST" workflow manually
   - Select use case and deploy

3. **Production Deployment**
   - Go to **Actions** tab
   - Run "Deploy to PROD" workflow
   - Requires approval and change ticket

## Troubleshooting

### Common Issues

1. **Workflow fails with "Environment not found"**
   - Ensure environment names match exactly: `development`, `test`, `production`

2. **Secrets not accessible**
   - Verify secrets are set in the specific environment, not repository-level

3. **Production deployment not requiring approval**
   - Check protection rules are configured in production environment

4. **Cannot create environments**
   - Ensure you have admin access to the repository

## Security Best Practices

1. **Rotate tokens regularly** - Update tokens every 90 days
2. **Use service principals** - Don't use personal access tokens
3. **Limit token scope** - Use minimal required permissions
4. **Monitor deployments** - Check Actions tab regularly
5. **Review protection rules** - Ensure appropriate reviewers

## Support

For issues:
- **GitHub Environments**: Check Settings → Environments
- **Workflow logs**: Actions tab → Select failed workflow
- **Secret issues**: Verify in environment settings
- **Databricks access**: Test tokens using Databricks CLI locally