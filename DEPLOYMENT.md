# Deployment Guide

## Multi-Environment Architecture

This project now supports clean environment isolation with consistent resource naming patterns.

### Environments

- **dev**: `dev.lawnsmartapp.com` - Development environment for testing
- **staging**: `staging.lawnsmartapp.com` - Staging environment for pre-production testing  
- **prod**: `lawnsmartapp.com` - Production environment

### Backend Configuration

All environments use a unified state management approach:
- **State Bucket**: `lawnsmartapp-terraform-state` (shared)
- **State Keys**: Environment-specific (`dev/terraform.tfstate`, `staging/terraform.tfstate`, `prod/terraform.tfstate`)
- **Lock Table**: `lawnsmartapp-terraform-locks` (shared)

## Deployment Script Usage

The unified `deploy.sh` script handles all environments and operations:

```bash
# Basic usage
./deploy.sh <environment> [command] [options]

# Examples
./deploy.sh dev plan                    # Plan changes for dev
./deploy.sh staging apply               # Apply changes to staging
./deploy.sh prod apply --auto-approve   # Apply to prod without confirmation
./deploy.sh dev destroy                 # Destroy dev infrastructure
./deploy.sh staging init                # Initialize staging backend
./deploy.sh dev validate                # Validate dev configuration
```

### Commands

- `init` - Initialize Terraform with environment-specific backend
- `validate` - Validate Terraform configuration
- `plan` - Plan infrastructure changes
- `apply` - Apply infrastructure changes
- `destroy` - Destroy infrastructure

### Options

- `--auto-approve` - Skip interactive approval for apply/destroy operations

## Environment Setup

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version 1.7.0+)
3. Proper IAM permissions for the target environment

### First-Time Setup

1. **Initialize the environment:**
   ```bash
   ./deploy.sh <environment> init
   ```

2. **Validate configuration:**
   ```bash
   ./deploy.sh <environment> validate
   ```

3. **Plan the deployment:**
   ```bash
   ./deploy.sh <environment> plan
   ```

4. **Apply the infrastructure:**
   ```bash
   ./deploy.sh <environment> apply
   ```

## GitHub Actions

The GitHub Actions workflow supports all environments:

### Automatic Deployments
- **Push to main**: Automatically deploys to `dev` environment
- **Pull Requests**: Runs plan and posts results as PR comments

### Manual Deployments
- Use workflow_dispatch to manually deploy to any environment
- Select environment: `dev`, `staging`, or `prod`
- Select action: `plan` or `apply`

### Required Secrets
- AWS OIDC role: `arn:aws:iam::600424110307:role/GithubActionsOIDC-LawnSmartApp-Role`

## Resource Naming Patterns

### Consistent Naming
All resources follow environment-specific naming patterns:

- **S3 Buckets**: `{environment}-lawnsmartapp-*` (e.g., `dev-lawnsmartapp-site-logs`)
- **IAM Roles**: `{environment}-lawnsmartapp-*` (e.g., `dev-lawnsmartapp-replication-role`)
- **Domains**: `{environment}.lawnsmartapp.com` (except prod: `lawnsmartapp.com`)

### Environment Isolation
- Each environment has completely isolated resources
- No naming conflicts between environments
- Safe to deploy/destroy environments independently

## Configuration Files

### Environment Variables
```
environments/
├── dev/terraform.tfvars      # Development configuration
├── staging/terraform.tfvars  # Staging configuration
└── prod/terraform.tfvars     # Production configuration
```

### Backend Configuration
```
backend-configs/
├── dev.conf       # Development backend
├── staging.conf   # Staging backend
└── prod.conf      # Production backend
```

## Security Features

### OIDC Authentication
- Uses GitHub OIDC instead of long-lived AWS keys
- Project-specific IAM roles with least privilege
- Repository isolation prevents cross-project access

### State Security
- S3 bucket encryption enabled
- Versioning enabled for state recovery
- Public access blocked
- DynamoDB state locking prevents concurrent modifications

## Troubleshooting

### Common Issues

1. **State lock errors:**
   ```bash
   # Check if DynamoDB table exists
   aws dynamodb describe-table --table-name lawnsmartapp-terraform-locks
   
   # Force unlock if needed (use carefully)
   terraform force-unlock <lock-id>
   ```

2. **Backend initialization errors:**
   ```bash
   # Reconfigure backend
   ./deploy.sh <environment> init
   ```

3. **Permission errors:**
   - Verify AWS credentials are configured
   - Check IAM role permissions
   - Ensure OIDC provider is properly configured

### State Management

- State files are stored in S3 with environment-specific keys
- Automatic backups via S3 versioning
- Shared lock table prevents concurrent modifications
- Use `terraform state list` to view current resources

## Migration from Previous Setup

If migrating from the previous setup:

1. **Backup existing state:**
   ```bash
   terraform state pull > backup-state.json
   ```

2. **Initialize new backend:**
   ```bash
   ./deploy.sh <environment> init
   ```

3. **Import existing resources if needed:**
   ```bash
   terraform import <resource_type>.<resource_name> <resource_id>
   ```

## Best Practices

### Development Workflow
1. Always test changes in `dev` environment first
2. Use `plan` command to review changes before applying
3. Tag deployments in Git for traceability
4. Use `staging` for final validation before production

### Security
- Never commit AWS credentials to Git
- Use least privilege IAM policies
- Enable CloudTrail for audit logging
- Regularly rotate OIDC provider thumbprints

### Monitoring
- Monitor CloudWatch logs for deployment issues
- Set up alarms for critical infrastructure components
- Use AWS Config for compliance monitoring