# Production Environment Configuration

**🔐 Security Policy: This project now uses GitHub Actions for all deployments. Local deployment scripts have been deprecated and archived.**

This directory contains the production environment configuration for the LawnSmart App AWS hosting infrastructure.

## Current Structure

```
environments/
├── prod/
│   ├── backend.conf      # Production backend configuration
│   └── terraform.tfvars  # Production variables
└── README.md            # This file
```

## Deployment Method

**🚀 All deployments MUST use GitHub Actions workflows:**

```bash
# Deploy infrastructure changes
gh workflow run "Terraform Deployment" --ref main

# Monitor deployment status
gh run list --limit 5
gh run view [RUN_ID] --web
```

## Production Configuration

| Setting | Value |
|---------|-------|
| **Domain** | lawnsmartapp.com |
| **State Location** | lawnsmartapp-terraform-state/lawnsmartapp-com/ |
| **Resource Prefix** | lawnsmartapp-* (clean production naming) |
| **Backend Config** | `environments/prod/backend.conf` |
| **Variables** | `environments/prod/terraform.tfvars` |

## Backend Configuration

Production uses dedicated state management:
- **State Bucket**: `lawnsmartapp-terraform-state`
- **State Key**: `lawnsmartapp-com/terraform.tfstate`
- **Lock Table**: `terraform-locks`
- **Region**: `us-east-1`
- **Encryption**: `true`

## Best Practices

1. **Use GitHub Actions for all deployments** - Local scripts are deprecated
2. **Monitor deployments** via GitHub Actions dashboard
3. **Review Terraform plans** in GitHub Actions logs before applying
4. **Use OIDC authentication** - No stored AWS credentials
5. **Follow GitOps workflow** - All changes via Git commits

## Local Development (Read-Only)

For local development and testing only:

```bash
# Format and validate (no deployment)
terraform fmt -recursive
terraform validate
terraform plan  # Requires AWS credentials for read-only preview
```

## Archived Multi-Environment Setup

Previous multi-environment configurations (dev/staging) have been simplified to production-only deployment. For information about the archived local deployment scripts, see `archived/README.md`.

## Security Features

- ✅ **OIDC Authentication**: GitHub Actions uses AWS OIDC, no stored credentials
- ✅ **Repository Isolation**: IAM trust policy restricted to this specific repository
- ✅ **Least Privilege**: IAM permissions scoped to required resources only
- ✅ **Audit Trail**: All deployments logged via GitHub Actions and CloudTrail
- ✅ **Encrypted State**: Terraform state encrypted at rest in S3