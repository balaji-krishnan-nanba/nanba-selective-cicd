# GitHub Secrets Setup Guide

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository settings.

### How to Add Secrets

1. Go to your repository: https://github.com/balaji-krishnan-nanba/nanba-selective-cicd
2. Click on **Settings** tab
3. Navigate to **Secrets and variables** → **Actions**
4. Click **New repository secret** for each secret below

### Secrets to Configure

Add these 6 secrets with their corresponding values:

| Secret Name | Description | 
|------------|-------------|
| `DATABRICKS_HOST_DEV` | Azure Databricks DEV workspace URL |
| `DATABRICKS_TOKEN_DEV` | Azure Databricks DEV access token |
| `DATABRICKS_HOST_TEST` | Azure Databricks TEST workspace URL |
| `DATABRICKS_TOKEN_TEST` | Azure Databricks TEST access token |
| `DATABRICKS_HOST_PROD` | Azure Databricks PROD workspace URL |
| `DATABRICKS_TOKEN_PROD` | Azure Databricks PROD access token |

### Setting up Environments (Optional but Recommended)

For better security, you can also set up GitHub Environments:

1. Go to **Settings** → **Environments**
2. Create three environments: `development`, `test`, `production`
3. For `production` environment:
   - Enable **Required reviewers**
   - Add protection rules as needed
   - Add environment-specific secrets

### Verify Setup

After adding all secrets:

1. Create a Pull Request from `feature/selective-cicd-setup` to `main`
2. The PR should trigger the "PR Validation and Deploy to DEV" workflow
3. Check the Actions tab to monitor the deployment

### Next Steps

1. **Create PR**: Create a pull request to trigger DEV deployment
2. **Test Deployment**: After merge, manually trigger TEST deployment
3. **Production**: Deploy to PROD with approval workflow

## Important Security Notes

- Never commit tokens or secrets directly in code
- Rotate tokens periodically
- Use least-privilege access for service principals
- Consider using Azure Key Vault for production environments

## Troubleshooting

If workflows fail:

1. Check that all 6 secrets are properly configured
2. Verify token permissions in Azure Databricks
3. Ensure workspace URLs are correct (without trailing slashes)
4. Check Actions logs for detailed error messages

## Support

For issues with:
- **Azure Databricks**: Check workspace access and token validity
- **GitHub Actions**: Review workflow logs in the Actions tab
- **Deployment**: Run `make validate` locally to test configuration