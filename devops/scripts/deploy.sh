#!/bin/bash

# Databricks Selective Deployment Script
# Usage: ./deploy.sh <environment> <use_case>
# Example: ./deploy.sh test usecase-1
# Example: ./deploy.sh prod all

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if databricks CLI is installed
check_databricks_cli() {
    if ! command -v databricks &> /dev/null; then
        print_message $RED "Error: Databricks CLI is not installed"
        print_message $YELLOW "Install it using: curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh"
        exit 1
    fi
}

# Function to validate environment
validate_environment() {
    local env=$1
    case $env in
        dev|test|prod)
            return 0
            ;;
        *)
            print_message $RED "Error: Invalid environment '$env'"
            print_message $YELLOW "Valid environments: dev, test, prod"
            exit 1
            ;;
    esac
}

# Function to validate use case
validate_use_case() {
    local use_case=$1
    case $use_case in
        usecase-1|usecase-2|all)
            return 0
            ;;
        *)
            print_message $RED "Error: Invalid use case '$use_case'"
            print_message $YELLOW "Valid use cases: usecase-1, usecase-2, all"
            exit 1
            ;;
    esac
}

# Function to deploy shared folder
deploy_shared() {
    local env=$1
    local workspace_path="/Workspace/Deployments/${env}/shared"
    
    print_message $GREEN "\n📁 Deploying shared folder to ${env}..."
    
    # Create workspace directory
    databricks workspace mkdirs "$workspace_path" || true
    
    # Import shared notebooks
    if [ -d "./src/shared" ]; then
        databricks workspace import-dir \
            ./src/shared \
            "$workspace_path" \
            --overwrite
        
        print_message $GREEN "✅ Shared folder deployed successfully"
        
        # List deployed files
        print_message $YELLOW "Deployed files:"
        databricks workspace ls "$workspace_path" 2>/dev/null || true
    else
        print_message $RED "⚠️  Warning: src/shared directory not found"
    fi
}

# Function to deploy a single use case
deploy_use_case() {
    local env=$1
    local use_case=$2
    local workspace_path="/Workspace/Deployments/${env}/${use_case}"
    
    print_message $GREEN "\n📁 Deploying ${use_case} to ${env}..."
    
    # Create workspace directory
    databricks workspace mkdirs "$workspace_path" || true
    
    # Import use case notebooks
    if [ -d "./src/${use_case}" ]; then
        databricks workspace import-dir \
            "./src/${use_case}" \
            "$workspace_path" \
            --overwrite
        
        print_message $GREEN "✅ ${use_case} deployed successfully"
        
        # List deployed files
        print_message $YELLOW "Deployed files:"
        databricks workspace ls "$workspace_path" 2>/dev/null || true
    else
        print_message $RED "⚠️  Warning: src/${use_case} directory not found"
    fi
}

# Function to deploy all use cases
deploy_all_use_cases() {
    local env=$1
    
    print_message $GREEN "\n📦 Deploying ALL use cases to ${env}..."
    
    # Deploy each use case
    deploy_use_case "$env" "usecase-1"
    deploy_use_case "$env" "usecase-2"
}

# Function to verify deployment
verify_deployment() {
    local env=$1
    local use_case=$2
    
    print_message $YELLOW "\n🔍 Verifying deployment..."
    
    # Check shared folder
    print_message $YELLOW "Checking shared folder:"
    databricks workspace ls "/Workspace/Deployments/${env}/shared" 2>/dev/null || \
        print_message $RED "Shared folder not found or empty"
    
    # Check use case folders
    if [ "$use_case" = "all" ]; then
        print_message $YELLOW "Checking usecase-1:"
        databricks workspace ls "/Workspace/Deployments/${env}/usecase-1" 2>/dev/null || \
            print_message $RED "usecase-1 not found or empty"
        
        print_message $YELLOW "Checking usecase-2:"
        databricks workspace ls "/Workspace/Deployments/${env}/usecase-2" 2>/dev/null || \
            print_message $RED "usecase-2 not found or empty"
    else
        print_message $YELLOW "Checking ${use_case}:"
        databricks workspace ls "/Workspace/Deployments/${env}/${use_case}" 2>/dev/null || \
            print_message $RED "${use_case} not found or empty"
    fi
}

# Main deployment function
main() {
    local env=$1
    local use_case=$2
    
    # Validate inputs
    if [ $# -ne 2 ]; then
        print_message $RED "Error: Invalid number of arguments"
        print_message $YELLOW "Usage: $0 <environment> <use_case>"
        print_message $YELLOW "Example: $0 test usecase-1"
        print_message $YELLOW "Example: $0 prod all"
        exit 1
    fi
    
    # Check prerequisites
    check_databricks_cli
    
    # Validate inputs
    validate_environment "$env"
    validate_use_case "$use_case"
    
    print_message $GREEN "=========================================="
    print_message $GREEN "🚀 Databricks Selective Deployment"
    print_message $GREEN "=========================================="
    print_message $YELLOW "Environment: ${env}"
    print_message $YELLOW "Use Case: ${use_case}"
    print_message $YELLOW "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    print_message $GREEN "=========================================="
    
    # Always deploy shared folder first
    deploy_shared "$env"
    
    # Deploy selected use case(s)
    if [ "$use_case" = "all" ]; then
        deploy_all_use_cases "$env"
    else
        deploy_use_case "$env" "$use_case"
    fi
    
    # Verify deployment
    verify_deployment "$env" "$use_case"
    
    print_message $GREEN "\n=========================================="
    print_message $GREEN "✅ Deployment completed successfully!"
    print_message $GREEN "=========================================="
    print_message $YELLOW "Workspace root: /Workspace/Deployments/${env}/"
    print_message $YELLOW "Deployed components:"
    print_message $YELLOW "  - shared folder (always deployed)"
    
    if [ "$use_case" = "all" ]; then
        print_message $YELLOW "  - usecase-1"
        print_message $YELLOW "  - usecase-2"
    else
        print_message $YELLOW "  - ${use_case}"
    fi
    
    print_message $GREEN "=========================================="
}

# Run main function with all arguments
main "$@"