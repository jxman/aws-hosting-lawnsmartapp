# GitHub Actions Workflow Configuration

**🔐 Security Policy: This project uses GitHub Actions as the exclusive deployment method with OIDC authentication.**

## Overview

The Terraform deployment workflow provides secure, automated infrastructure deployment for the LawnSmartApp hosting environment using GitHub Actions with AWS OIDC authentication.

## Key Features

### 1. Production-Only Deployment
- **Simplified Architecture**: Single production environment deployment
- **Clean Resource Naming**: Uses `lawnsmartapp-*` naming convention
- **Secure State Management**: Dedicated S3 bucket and DynamoDB table

### 2. OIDC Authentication
- **No Stored Credentials**: Uses AWS OIDC web identity federation
- **Repository Isolation**: IAM role restricted to this specific repository
- **Least Privilege**: IAM permissions scoped to required resources only

### 3. Automated Infrastructure Management
- **State Infrastructure**: Creates S3 bucket and DynamoDB table automatically
- **Format Validation**: Checks Terraform code formatting
- **Plan Review**: Generates and validates infrastructure changes
- **Automatic Application**: Applies changes on main branch pushes

## Current Configuration

### Production Environment Settings
```yaml
env:
  ENVIRONMENT: prod  # Fixed to production-only deployment
```

### Infrastructure Created
The workflow creates and manages:
- **S3 Bucket**: `lawnsmartapp-terraform-state`
- **State Key**: `lawnsmartapp-com/terraform.tfstate`
- **DynamoDB Table**: `terraform-locks`
- **Domain**: `lawnsmartapp.com`

### Backend Configuration
```bash
# Backend initialization
terraform init -backend-config=environments/prod/backend.conf

# Planning with production variables
terraform plan -var-file=environments/prod/terraform.tfvars
```

## Workflow Triggers

### Automatic Triggers
- **Push to main**: Automatically deploys infrastructure changes
- **Pull Requests**: Runs plan and validation (no deployment)

### Manual Triggers
```bash
# Manual deployment trigger
gh workflow run "Terraform Deployment" --ref main

# Manual deployment with apply
gh workflow run "Terraform Deployment" --ref main -f action=apply
```

## Deployment Process

### Workflow Steps
1. **Setup**: Checkout code, setup Terraform 1.7.0, configure AWS OIDC credentials
2. **State Verification**: Check existing state file location and list all state files
3. **Infrastructure**: Create/verify S3 state bucket and DynamoDB lock table
4. **Validation**: Format check, init with production backend, validate configuration
5. **Planning**: Generate plan with production variables, upload artifacts for PRs
6. **Deployment**: Apply changes (on main branch or manual apply)
7. **Post-Deploy**: Output resources, invalidate CloudFront cache

### Security Features
- ✅ **OIDC Authentication**: `arn:aws:iam::600424110307:role/GithubActionsOIDC-LawnSmartApp-Role`
- ✅ **Repository Isolation**: Trust policy restricted to `jxman/aws-hosting-lawnsmartapp`
- ✅ **Encrypted State**: S3 state bucket with AES256 encryption
- ✅ **State Locking**: DynamoDB prevents concurrent modifications
- ✅ **Least Privilege**: IAM permissions limited to required resources

## Production Resources

### Current Infrastructure
| Resource Type | Name/ID | Purpose |
|---------------|---------|---------|
| **Domain** | lawnsmartapp.com | Production website |
| **CloudFront** | E1MYY1CD3E7WBQ | CDN distribution |
| **S3 Primary** | www.lawnsmartapp.com | Website hosting |
| **S3 Failover** | prod-lawnsmartapp-secondary | Cross-region backup |
| **S3 Logs** | prod-lawnsmartapp-site-logs | Access logging |
| **Route53 Zone** | Z04860973DG1BJ5J1VVBE | DNS management |
| **ACM Certificate** | 08e59308-3109-4531-9895-c4d77ba3636c | SSL/TLS |

### IAM Resources
- **OIDC Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **OIDC Policy**: `GithubActions-LawnSmartApp-Policy`
- **OIDC Provider**: `token.actions.githubusercontent.com`
- **Replication Role**: `prod-lawnsmartapp-replication-role`

## Monitoring Deployments

### Command Line Monitoring
```bash
# Check recent workflow runs
gh run list --limit 10

# View specific deployment
gh run view [RUN_ID]

# Watch deployment in browser
gh run view [RUN_ID] --web

# Check deployment status
gh run list --status completed --limit 5
gh run list --status failure --limit 5
```

### Deployment Status Indicators
| Status | Description | Action Required |
|--------|-------------|-----------------|
| ✅ **Success** | Deployment completed successfully | None |
| 🔄 **In Progress** | Deployment currently running | Monitor |
| ❌ **Failure** | Deployment failed | Check logs and fix issues |
| ⏸️ **Cancelled** | Deployment was cancelled | Re-run if needed |

## Pull Request Integration

### Automated PR Features
- **Plan Comments**: Automatically posts Terraform plan results
- **Plan Artifacts**: Uploads plan files for review
- **Format Validation**: Checks Terraform code formatting
- **No Deployment**: PRs only validate, never apply changes

### PR Workflow
1. Create pull request with infrastructure changes
2. Workflow runs format check, validation, and plan
3. Plan results posted as PR comment
4. Review and approve changes
5. Merge to main triggers automatic deployment

## Best Practices

### Development Workflow
1. **Make Changes**: Edit Terraform files locally
2. **Format Code**: Run `terraform fmt -recursive`
3. **Validate Locally**: Run `terraform validate`
4. **Create PR**: Submit for review with automatic plan
5. **Review Plan**: Check plan results in PR comments
6. **Merge**: Automatic deployment to production

### Security Guidelines
- **Never bypass GitHub Actions**: All deployments must use the workflow
- **Review plans carefully**: Always check Terraform plans before merging
- **Monitor deployments**: Watch GitHub Actions logs for deployment status
- **Use least privilege**: IAM roles have minimal required permissions

## Troubleshooting

### Common Issues

#### Authentication Errors
```
Error: Could not assume role with OIDC
```
**Solution**: Verify OIDC provider and IAM role trust policy configuration

#### State Lock Issues
```
Error: Error acquiring the state lock
```
**Solution**: Check DynamoDB table status and clear locks if needed:
```bash
aws dynamodb scan --table-name terraform-locks
terraform force-unlock [LOCK_ID]
```

#### S3 Bucket Issues
```
Error: deleting S3 Bucket: BucketNotEmpty
```
**Solution**: Empty bucket contents including versioned objects:
```bash
aws s3 rm s3://bucket-name --recursive
aws s3api delete-objects --bucket bucket-name --delete "$(aws s3api list-object-versions --bucket bucket-name --output json | jq '{Objects: [.Versions[]? + .DeleteMarkers[]? | {Key: .Key, VersionId: .VersionId}]}')"
```

### Debugging Commands
```bash
# Check workflow logs
gh run view [RUN_ID] --log

# Download logs for offline analysis
gh run download [RUN_ID]

# Verify AWS resources
aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`lawnsmartapp.com CloudFront`]'
aws s3 ls | grep lawnsmartapp
aws route53 list-resource-record-sets --hosted-zone-id Z04860973DG1BJ5J1VVBE
```

## Migration from Local Scripts

### What Changed
- **Local Scripts**: Moved to `archived/local-deployment-scripts/`
- **Deployment Method**: Now exclusively GitHub Actions
- **Environment**: Simplified to production-only
- **Authentication**: Uses OIDC instead of local AWS credentials

### Migration Benefits
- **Enhanced Security**: No stored credentials, OIDC authentication
- **Team Visibility**: All deployments visible to team members
- **Audit Trail**: Complete deployment history in GitHub
- **Consistency**: Same deployment environment for all team members

## Emergency Procedures

### Emergency Rollback
```bash
# Method 1: Git rollback + redeploy
git checkout [WORKING_COMMIT_HASH]
git checkout -b emergency-rollback
git push origin emergency-rollback
gh workflow run "Terraform Deployment" --ref emergency-rollback

# Method 2: Re-run previous successful deployment
gh run list --status completed --limit 5
gh run rerun [SUCCESSFUL_RUN_ID]
```

### Manual Recovery
**⚠️ Only use in extreme emergencies when GitHub Actions is unavailable**

## Current Status

- ✅ **Deployment Method**: GitHub Actions with OIDC authentication
- ✅ **Environment**: Production-only deployment
- ✅ **Domain**: lawnsmartapp.com (active and resolving)
- ✅ **Security**: Repository-isolated IAM role with least privilege
- ✅ **Documentation**: Comprehensive deployment guide available

---

**🌱 LawnSmart App - Production Infrastructure**  
*Deployed securely with GitHub Actions + AWS OIDC + Terraform*