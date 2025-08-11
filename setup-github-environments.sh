#!/bin/bash

# GitHub repository details
REPO="balaji-krishnan-nanba/nanba-selective-cicd"

echo "============================================="
echo "GitHub Environments Setup Script"
echo "============================================="
echo ""
echo "This script will create GitHub environments and set secrets"
echo "Repository: $REPO"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is authenticated"
echo ""

# Function to create environment and set secrets
setup_environment() {
    local env_name=$1
    local display_name=$2
    local databricks_host=$3
    local databricks_token=$4
    local requires_approval=$5
    
    echo "Setting up environment: $display_name ($env_name)"
    echo "----------------------------------------"
    
    # Create environment (this requires API call as gh doesn't have direct command)
    echo "Creating environment: $env_name"
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$REPO/environments/$env_name" \
        -f wait_timer=0 \
        > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Environment created/updated: $env_name"
    else
        echo "⚠️  Environment might already exist: $env_name"
    fi
    
    # Set environment-specific secrets
    echo "Setting secrets for $env_name..."
    
    # Set DATABRICKS_HOST
    echo -n "$databricks_host" | gh secret set DATABRICKS_HOST --env "$env_name" --repo "$REPO"
    if [ $? -eq 0 ]; then
        echo "  ✅ DATABRICKS_HOST set"
    else
        echo "  ❌ Failed to set DATABRICKS_HOST"
    fi
    
    # Set DATABRICKS_TOKEN
    echo -n "$databricks_token" | gh secret set DATABRICKS_TOKEN --env "$env_name" --repo "$REPO"
    if [ $? -eq 0 ]; then
        echo "  ✅ DATABRICKS_TOKEN set"
    else
        echo "  ❌ Failed to set DATABRICKS_TOKEN"
    fi
    
    # Configure protection rules for production
    if [ "$requires_approval" = "true" ]; then
        echo "Configuring protection rules for $env_name..."
        
        # Get the current user as reviewer (you may want to change this)
        REVIEWER=$(gh api user --jq .login)
        
        # Set protection rules (requires admin access)
        gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "/repos/$REPO/environments/$env_name" \
            -f wait_timer=0 \
            --field reviewers[][type]=User \
            --field reviewers[][id]="$(gh api users/$REVIEWER --jq .id)" \
            --field deployment_branch_policy[protected_branches]=true \
            --field deployment_branch_policy[custom_branch_policies]=false \
            > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "  ✅ Protection rules configured (requires approval from: $REVIEWER)"
        else
            echo "  ⚠️  Could not set protection rules (may require admin access)"
        fi
    fi
    
    echo ""
}

# Prompt for Azure Databricks details
echo "Please enter the Azure Databricks details:"
echo ""

read -p "DEV Workspace URL (e.g., https://adb-xxx.azuredatabricks.net): " DEV_HOST
read -p "DEV Access Token: " DEV_TOKEN
echo ""

read -p "TEST Workspace URL: " TEST_HOST
read -p "TEST Access Token: " TEST_TOKEN
echo ""

read -p "PROD Workspace URL: " PROD_HOST
read -p "PROD Access Token: " PROD_TOKEN
echo ""

# Setup environments
echo "============================================="
echo "Creating GitHub Environments"
echo "============================================="
echo ""

# Development environment
setup_environment "development" "Development" "$DEV_HOST" "$DEV_TOKEN" "false"

# Test environment  
setup_environment "test" "Test" "$TEST_HOST" "$TEST_TOKEN" "false"

# Production environment (with approval required)
setup_environment "production" "Production" "$PROD_HOST" "$PROD_TOKEN" "true"

echo "============================================="
echo "✅ GitHub Environments Setup Complete!"
echo "============================================="
echo ""
echo "Created environments:"
echo "  - development (no approval required)"
echo "  - test (no approval required)"
echo "  - production (approval required)"
echo ""
echo "Each environment has its own:"
echo "  - DATABRICKS_HOST"
echo "  - DATABRICKS_TOKEN"
echo ""
echo "Next steps:"
echo "1. Create a PR from feature/selective-cicd-setup to main"
echo "2. The PR will trigger deployment to development environment"
echo "3. After merge, use manual workflows for test and production"
echo ""
echo "View environments at:"
echo "https://github.com/$REPO/settings/environments"