# Verify Your Databricks Setup

## Check Your Workspace URLs

Make sure your workspace URLs in GitHub environment variables are in the correct format:

### Expected Format
```
https://adb-XXXXXXXXX.XX.azuredatabricks.net
```

### Your Current Setup (Based on Error)
The error shows the system is trying to connect to:
```
https://adb-2723413612442127.7.azuredatabricks.net
```

## Troubleshooting Steps

### 1. Verify Workspace URLs in Azure Portal

1. Go to Azure Portal
2. Navigate to your Resource Group: `databricks-cicd-rsg`
3. Check each Databricks workspace:
   - `databricks-cicd-dev`
   - `databricks-cicd-test`
   - `databricks-cicd-prod`
4. Click on each workspace and find the **Workspace URL**
5. Copy the full URL (including `https://`)

### 2. Update GitHub Environment Variables

For each environment in GitHub:

1. Go to: https://github.com/balaji-krishnan-nanba/nanba-selective-cicd/settings/environments
2. Click on each environment (`development`, `test`, `production`)
3. Update the `DATABRICKS_HOST` variable with the correct URL from Azure
4. Make sure the URL:
   - Starts with `https://`
   - Has no trailing slash
   - Is accessible from your browser

### 3. Test Connectivity Locally

Test each workspace URL locally:

```bash
# Test DEV workspace
curl -X GET \
  https://adb-XXXXXXXXX.XX.azuredatabricks.net/api/2.0/clusters/list \
  -H "Authorization: Bearer YOUR_TOKEN"

# You should get a response (even if it's an auth error)
# If you get "no such host", the URL is incorrect
```

### 4. Common Issues

#### Issue: "no such host"
**Cause**: The workspace URL is incorrect or the workspace doesn't exist
**Solution**: Get the correct URL from Azure Portal

#### Issue: "401 Unauthorized"
**Cause**: Token is invalid or expired
**Solution**: Generate a new token from Databricks workspace

#### Issue: "403 Forbidden"
**Cause**: Token doesn't have required permissions
**Solution**: Create token with appropriate permissions

## Alternative Workspace URL Formats

Sometimes Azure Databricks workspaces use different URL formats:

1. **Standard Format**: `https://adb-XXXXXXXXX.XX.azuredatabricks.net`
2. **Regional Format**: `https://REGION.azuredatabricks.net/?o=XXXXXXXXX`
3. **Custom Domain**: `https://your-custom-domain.databricks.com`

## Quick Fix if Workspaces Don't Exist

If the workspaces haven't been created yet:

1. Create them in Azure Portal first
2. Or use existing workspace URLs if you have other workspaces
3. Update the GitHub environment variables with the correct URLs

## Verify Token Permissions

Your Databricks tokens need these permissions:
- Workspace access
- Ability to create/manage clusters
- Ability to import notebooks

## Next Steps

Once you've verified and updated the URLs:

1. Re-run the failed workflow
2. Check the "Test Databricks Connectivity" step output
3. If connectivity passes, the deployment should proceed

## Contact Support

If workspaces exist but URLs still don't work:
- Check with your Azure admin for network restrictions
- Verify firewall rules allow GitHub Actions to access Azure
- Check if private endpoints are configured (GitHub Actions needs public access)