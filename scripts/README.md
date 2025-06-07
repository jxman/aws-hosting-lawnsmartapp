# Deployment Scripts

This directory contains deployment scripts for different environments of the Terraform S3 + CloudFront infrastructure.

## Available Scripts

### Production Deployment
```bash
./deploy-prod.sh [plan|apply|destroy]
```

### Development Deployment  
```bash
./deploy-dev.sh [plan|apply|destroy]
```

## Usage Examples

### Plan Changes
```bash
# Production planning
./deploy-prod.sh plan

# Development planning
./deploy-dev.sh plan
```

### Deploy Changes
```bash
# Deploy to production (requires confirmation)
./deploy-prod.sh apply

# Deploy to development
./deploy-dev.sh apply
```

### Destroy Environment
```bash
# Destroy production (requires typing 'DELETE')
./deploy-prod.sh destroy

# Destroy development (requires typing 'yes')
./deploy-dev.sh destroy
```

## Features

### Safety Features
- ✅ **Prerequisites checking** - Validates Terraform, AWS CLI, and credentials
- ✅ **Configuration validation** - Ensures all required files exist
- ✅ **Environment isolation** - Uses environment-specific backend configs
- ✅ **Confirmation prompts** - Prevents accidental deployments
- ✅ **Clean initialization** - Removes stale .terraform directories
- ✅ **Error handling** - Exits on any command failure

### Production Safety
- 🔒 **Strict confirmation** - Requires typing 'yes' to apply
- 🔒 **Destruction protection** - Requires typing 'DELETE' in caps
- 🔒 **Configuration display** - Shows what will be deployed
- 🔒 **AWS account verification** - Displays target account

### Development Convenience
- 🚀 **Faster confirmations** - Simple y/N prompts
- 🚀 **Less strict validation** - Easier to iterate quickly
- 🚀 **Clear environment labeling** - Obvious when in dev mode

## What Each Script Does

### 1. Prerequisites Check
- Verifies Terraform installation
- Verifies AWS CLI installation  
- Checks for backend configuration files
- Checks for variable files
- Validates AWS credentials

### 2. Configuration Display
- Shows target environment
- Shows backend configuration file
- Shows variables file
- Shows AWS account ID
- Shows AWS region

### 3. Terraform Operations
- Clean initialization with environment-specific backend
- Configuration validation
- Plan generation with environment variables
- Safe apply with confirmation
- Automatic CloudFront cache invalidation
- Resource output display

### 4. Post-Deployment
- Shows Terraform outputs
- Invalidates CloudFront cache automatically
- Cleans up temporary plan files

## Error Handling

The scripts will exit with appropriate error messages if:
- Required tools are not installed
- Configuration files are missing
- AWS credentials are invalid
- Terraform commands fail
- User cancels operations

## Security Considerations

### Production Script
- Requires explicit 'yes' confirmation for apply
- Requires typing 'DELETE' in capitals for destroy
- Shows warning messages about production impact
- Displays AWS account for verification

### Development Script  
- Uses simpler y/N confirmations
- Less strict destruction requirements
- Still validates credentials and configuration
- Clear labeling as development environment

## Customization

### Adding New Environments
To add a staging deployment script:

1. Copy `deploy-dev.sh` to `deploy-staging.sh`
2. Change `ENVIRONMENT="dev"` to `ENVIRONMENT="staging"`
3. Update script title and messages
4. Make executable: `chmod +x deploy-staging.sh`

### Modifying Confirmation Requirements
Edit the confirmation prompts in the `terraform_apply()` and `terraform_destroy()` functions to match your security requirements.

## Integration with CI/CD

These scripts can be called from CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Deploy to Production
  run: ./deploy-prod.sh apply
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

However, for production use, the GitHub Actions workflow is recommended as it provides better logging, approval workflows, and integration with PR processes.