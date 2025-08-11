#!/usr/bin/env python3
"""
Databricks Deployment Validation Script
Validates that notebooks are correctly deployed to the Databricks workspace
"""

import sys
import json
import argparse
import requests
from typing import List, Dict, Optional
import os
from datetime import datetime


class DeploymentValidator:
    """Validates Databricks deployments"""
    
    def __init__(self, host: str, token: str, env: str):
        """
        Initialize the validator
        
        Args:
            host: Databricks workspace host URL
            token: Databricks access token
            env: Environment name (dev, test, prod)
        """
        self.host = host.rstrip('/')
        self.token = token
        self.env = env
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        # All environments now use standard shared paths with bundle structure
        self.base_path = f"/Workspace/Deployments/{env}/files/src"
        self.validation_results = []
        
    def _make_request(self, endpoint: str, method: str = 'GET', data: Dict = None) -> Optional[Dict]:
        """
        Make API request to Databricks
        
        Args:
            endpoint: API endpoint
            method: HTTP method
            data: Request data
            
        Returns:
            Response JSON or None if error
        """
        # Ensure endpoint starts with /api/2.0 if not already
        if not endpoint.startswith('/api/2.0'):
            endpoint = f"/api/2.0{endpoint}"
        url = f"{self.host}{endpoint}"
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers)
            elif method == 'POST':
                response = requests.post(url, headers=self.headers, json=data)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            if response.status_code == 200:
                return response.json()
            else:
                print(f"❌ API request failed: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"❌ Request error: {e}")
            return None
    
    def check_path_exists(self, path: str) -> bool:
        """
        Check if a path exists in the workspace
        
        Args:
            path: Workspace path to check
            
        Returns:
            True if path exists, False otherwise
        """
        data = {'path': path}
        response = self._make_request('/workspace/get-status', 'POST', data)
        
        if response and 'path' in response:
            return True
        return False
    
    def list_notebooks(self, path: str) -> List[str]:
        """
        List notebooks in a directory
        
        Args:
            path: Directory path
            
        Returns:
            List of notebook paths
        """
        data = {'path': path}
        response = self._make_request('/workspace/list', 'POST', data)
        
        notebooks = []
        if response and 'objects' in response:
            for obj in response['objects']:
                if obj.get('object_type') == 'NOTEBOOK':
                    notebooks.append(obj['path'])
                elif obj.get('object_type') == 'DIRECTORY':
                    # Recursively list notebooks in subdirectories
                    sub_notebooks = self.list_notebooks(obj['path'])
                    notebooks.extend(sub_notebooks)
        
        return notebooks
    
    def validate_shared_folder(self) -> bool:
        """
        Validate that shared folder is deployed
        
        Returns:
            True if validation passes
        """
        print("\n📁 Validating shared folder deployment...")
        
        shared_path = f"{self.base_path}/shared"
        
        # Check if shared folder exists
        if not self.check_path_exists(shared_path):
            self.validation_results.append({
                'component': 'shared',
                'status': 'FAILED',
                'message': f'Shared folder not found at {shared_path}'
            })
            print(f"  ❌ Shared folder not found at {shared_path}")
            return False
        
        # List notebooks in shared folder
        notebooks = self.list_notebooks(shared_path)
        
        if not notebooks:
            self.validation_results.append({
                'component': 'shared',
                'status': 'WARNING',
                'message': 'Shared folder exists but contains no notebooks'
            })
            print(f"  ⚠️  Shared folder exists but contains no notebooks")
            return True
        
        self.validation_results.append({
            'component': 'shared',
            'status': 'PASSED',
            'message': f'Found {len(notebooks)} notebooks in shared folder',
            'notebooks': notebooks
        })
        
        print(f"  ✅ Shared folder validated - {len(notebooks)} notebooks found")
        for notebook in notebooks:
            print(f"     - {notebook.split('/')[-1]}")
        
        return True
    
    def validate_use_case(self, use_case: str) -> bool:
        """
        Validate that a use case is deployed
        
        Args:
            use_case: Use case name (usecase-1, usecase-2)
            
        Returns:
            True if validation passes
        """
        print(f"\n📁 Validating {use_case} deployment...")
        
        use_case_path = f"{self.base_path}/{use_case}"
        
        # Check if use case folder exists
        if not self.check_path_exists(use_case_path):
            self.validation_results.append({
                'component': use_case,
                'status': 'FAILED',
                'message': f'{use_case} folder not found at {use_case_path}'
            })
            print(f"  ❌ {use_case} folder not found at {use_case_path}")
            return False
        
        # List notebooks in use case folder
        notebooks = self.list_notebooks(use_case_path)
        
        if not notebooks:
            self.validation_results.append({
                'component': use_case,
                'status': 'WARNING',
                'message': f'{use_case} folder exists but contains no notebooks'
            })
            print(f"  ⚠️  {use_case} folder exists but contains no notebooks")
            return True
        
        self.validation_results.append({
            'component': use_case,
            'status': 'PASSED',
            'message': f'Found {len(notebooks)} notebooks in {use_case}',
            'notebooks': notebooks
        })
        
        print(f"  ✅ {use_case} validated - {len(notebooks)} notebooks found")
        for notebook in notebooks:
            print(f"     - {notebook.split('/')[-1]}")
        
        return True
    
    def validate_cluster(self, cluster_name: str) -> bool:
        """
        Validate that cluster configuration exists
        
        Args:
            cluster_name: Name of the cluster
            
        Returns:
            True if cluster exists
        """
        print(f"\n⚙️  Validating cluster: {cluster_name}...")
        
        response = self._make_request('/clusters/list')
        
        if response and 'clusters' in response:
            for cluster in response['clusters']:
                if cluster.get('cluster_name') == cluster_name:
                    self.validation_results.append({
                        'component': f'cluster-{cluster_name}',
                        'status': 'PASSED',
                        'message': f'Cluster {cluster_name} found',
                        'cluster_state': cluster.get('state')
                    })
                    print(f"  ✅ Cluster {cluster_name} found (state: {cluster.get('state')})")
                    return True
        
        self.validation_results.append({
            'component': f'cluster-{cluster_name}',
            'status': 'WARNING',
            'message': f'Cluster {cluster_name} not found'
        })
        print(f"  ⚠️  Cluster {cluster_name} not found")
        return False
    
    def run_smoke_test(self) -> bool:
        """
        Run basic smoke tests
        
        Returns:
            True if smoke tests pass
        """
        print("\n🔥 Running smoke tests...")
        
        # Test workspace API connectivity - check bundle root
        bundle_root = f"/Workspace/Deployments/{self.env}"
        response = self._make_request('/workspace/get-status', 'POST', {'path': bundle_root})
        if response:
            print(f"  ✅ Workspace API connectivity verified - bundle root exists at {bundle_root}")
            return True
        else:
            print("  ❌ Workspace API connectivity failed")
            return False
    
    def generate_report(self) -> Dict:
        """
        Generate validation report
        
        Returns:
            Validation report dictionary
        """
        report = {
            'environment': self.env,
            'timestamp': datetime.now().isoformat(),
            'workspace_host': self.host,
            'base_path': self.base_path,
            'validation_results': self.validation_results,
            'summary': {
                'total_checks': len(self.validation_results),
                'passed': len([r for r in self.validation_results if r['status'] == 'PASSED']),
                'failed': len([r for r in self.validation_results if r['status'] == 'FAILED']),
                'warnings': len([r for r in self.validation_results if r['status'] == 'WARNING'])
            }
        }
        
        return report


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Validate Databricks deployment')
    parser.add_argument('--env', required=True, choices=['dev', 'test', 'prod'],
                        help='Environment to validate')
    parser.add_argument('--host', required=False, help='Databricks workspace host')
    parser.add_argument('--token', required=False, help='Databricks access token')
    parser.add_argument('--use-case', choices=['usecase-1', 'usecase-2', 'all'],
                        help='Specific use case to validate')
    parser.add_argument('--validate-all', action='store_true',
                        help='Validate all components')
    parser.add_argument('--smoke-test', action='store_true',
                        help='Run smoke tests only')
    parser.add_argument('--output-json', help='Output report to JSON file')
    
    args = parser.parse_args()
    
    # Get credentials from environment if not provided
    host = args.host or os.environ.get('DATABRICKS_HOST')
    token = args.token or os.environ.get('DATABRICKS_TOKEN')
    
    if not host or not token:
        print("❌ Error: Databricks host and token are required")
        print("   Set DATABRICKS_HOST and DATABRICKS_TOKEN environment variables")
        print("   Or provide --host and --token arguments")
        sys.exit(1)
    
    # Initialize validator
    validator = DeploymentValidator(host, token, args.env)
    
    print("=" * 50)
    print(f"🔍 Databricks Deployment Validation")
    print(f"   Environment: {args.env}")
    print(f"   Workspace: {host}")
    print(f"   Bundle Path: /Workspace/Deployments/{args.env}/files/src")
    print(f"   Validation Path: {validator.base_path}")
    print("=" * 50)
    
    # Run validations
    all_passed = True
    
    if args.smoke_test:
        all_passed = validator.run_smoke_test()
    else:
        # Always validate shared folder
        if not validator.validate_shared_folder():
            all_passed = False
        
        # Validate use cases
        if args.validate_all or args.use_case == 'all':
            if not validator.validate_use_case('usecase-1'):
                all_passed = False
            if not validator.validate_use_case('usecase-2'):
                all_passed = False
        elif args.use_case:
            if not validator.validate_use_case(args.use_case):
                all_passed = False
        
        # Validate cluster
        cluster_name = f"{args.env}-cluster"
        validator.validate_cluster(cluster_name)
    
    # Generate report
    report = validator.generate_report()
    
    print("\n" + "=" * 50)
    print("📊 Validation Summary")
    print(f"   Total Checks: {report['summary']['total_checks']}")
    print(f"   ✅ Passed: {report['summary']['passed']}")
    print(f"   ❌ Failed: {report['summary']['failed']}")
    print(f"   ⚠️  Warnings: {report['summary']['warnings']}")
    print("=" * 50)
    
    # Save report if requested
    if args.output_json:
        with open(args.output_json, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"\n📄 Report saved to: {args.output_json}")
    
    # Exit with appropriate code
    if report['summary']['failed'] > 0:
        print("\n❌ Validation FAILED")
        sys.exit(1)
    else:
        print("\n✅ Validation PASSED")
        sys.exit(0)


if __name__ == '__main__':
    main()