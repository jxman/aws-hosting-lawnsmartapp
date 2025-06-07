# GitHub Actions Workflow Configuration

## Overview

The Terraform deployment workflow has been updated to align with the new environment-specific backend configuration approach. The workflow now supports multiple environments (dev, staging, prod) using the same configuration files as local development.

## Key Changes Made

### 1. Environment-Specific Configuration
- **Before:** Hardcoded production values in workflow
- **After:** Uses `ENVIRONMENT` variable to determine which configuration to use

### 2. Backend Configuration
- **Before:** Hardcoded backend config in workflow steps
- **After:** Uses environment-specific `backend.conf` files

### 3. Variable Files
- **Before:** Hardcoded Terraform variables as environment variables
- **After:** Uses environment-specific `terraform.tfvars` files

### 4. Infrastructure Creation
- **Before:** Created only S3 bucket, but tried to use DynamoDB locking
- **After:** Creates both S3 bucket AND DynamoDB table for proper state locking

## Current Configuration

### Environment Selection
```yaml
env:
  ENVIRONMENT: "prod"  # Change to 'dev' or 'staging' for other environments
```

### Infrastructure Created
For each environment, the workflow creates:
- S3 bucket: `synepho-terraform-state-${ENVIRONMENT}`
- DynamoDB table: `terraform-locks-${ENVIRONMENT}`

### Commands Used
```bash
# Backend initialization
terraform init -backend-config=environments/${ENVIRONMENT}/backend.conf

# Planning with environment-specific variables
terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars
```

## Multi-Environment Support

### To Deploy to Different Environments

1. **For Development:**
   ```yaml
   env:
     ENVIRONMENT: "dev"
   ```

2. **For Staging:**
   ```yaml
   env:
     ENVIRONMENT: "staging"
   ```

3. **For Production:**
   ```yaml
   env:
     ENVIRONMENT: "prod"
   ```

### Environment-Specific Resources

| Environment | State Bucket | Lock Table | Site Domain |
|-------------|--------------|------------|-------------|
| prod | synepho-terraform-state-prod | terraform-locks-prod | synepho.com |
| staging | synepho-terraform-state-staging | terraform-locks-staging | staging.synepho.com |
| dev | synepho-terraform-state-dev | terraform-locks-dev | dev.synepho.com |

## Workflow Features

### Triggers
- Push to `main` branch (for Terraform files or workflow changes)
- Pull requests to `main` branch
- Manual workflow dispatch

### Steps
1. **Setup:** Checkout code, setup Terraform, configure AWS credentials
2. **Infrastructure:** Create/verify state bucket and DynamoDB table
3. **Validation:** Format check, init, validate
4. **Planning:** Generate plan with environment-specific variables
5. **Deployment:** Apply changes (only on main branch)
6. **Post-Deploy:** Output resources, invalidate CloudFront cache

### Pull Request Integration
- Automatically posts Terraform plan results as PR comments
- Uploads plan artifacts for review
- Validates changes without applying them

## Best Practices

### Security
- Uses OIDC authentication with AWS (no long-lived credentials)
- State files are encrypted at rest
- DynamoDB locking prevents concurrent modifications

### State Management
- Environment-specific state isolation
- Versioned S3 buckets for state recovery
- Consistent state file locations between local and CI/CD

### Error Handling
- Continues on format check failures (warning only)
- Fails fast on validation or plan errors
- Comprehensive logging for troubleshooting

## Migration Notes

### From Old Workflow
If migrating from the previous hardcoded workflow:

1. **State File Location:** The workflow now uses `terraform.tfstate` as the key instead of `synepho-com/terraform.tfstate`
2. **DynamoDB Tables:** New tables will be created with environment-specific names
3. **Variables:** Switch from environment variables to var files

### Existing State Files
If you have existing state files in the old location:
```bash
# Copy existing state to new location (if needed)
aws s3 cp s3://synepho-terraform-state/synepho-com/terraform.tfstate s3://synepho-terraform-state-prod/terraform.tfstate
```

## Troubleshooting

### Common Issues

1. **"Backend config has changed"**
   - Delete `.terraform/` directory locally
   - Re-run `terraform init -backend-config=environments/prod/backend.conf`

2. **"State lock table not found"**
   - Ensure DynamoDB table exists with correct name
   - Check AWS permissions for DynamoDB operations

3. **"State file not found"**
   - Verify S3 bucket and key names match backend config
   - Check AWS permissions for S3 operations

### Debugging Commands
```bash
# Check backend configuration
cat .terraform/terraform.tfstate | jq '.backend.config'

# List state resources
terraform state list

# Verify infrastructure exists
aws s3 ls s3://synepho-terraform-state-prod/
aws dynamodb describe-table --table-name terraform-locks-prod
```

## Future Enhancements

### Planned Improvements
- [ ] Matrix builds for multiple environments
- [ ] Approval workflows for production deployments
- [ ] Integration with external secret management
- [ ] Cost estimation in PR comments
- [ ] Automated rollback capabilities

### Security Enhancements
- [ ] Policy as code validation
- [ ] Security scanning integration
- [ ] Compliance checking
- [ ] Drift detection and remediation