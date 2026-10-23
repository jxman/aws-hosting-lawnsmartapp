# Environment Configuration

**🔐 Security Policy: This project now uses GitHub Actions for all deployments. Local deployment scripts have been deprecated and archived.**

This directory holds the backend and variable files for each environment. CI uses only `prod`; `dev` and `staging` are for manual plans.

## Current Structure

```
environments/
├── prod/                 # Used by CI
│   ├── backend.conf      # State bucket lawnsmartapp-terraform-state
│   └── terraform.tfvars  # Production variables (incl. aws_application_arn)
├── dev/                  # Manual only; dev.lawnsmartapp.com
│   ├── backend.conf
│   └── terraform.tfvars
├── staging/              # Manual only; state bucket not created yet
│   ├── backend.conf
│   └── terraform.tfvars
└── README.md             # This file
```

## Deployment Method

**🚀 All deployments MUST use GitHub Actions workflows:**

```bash
# A push to main plans and applies. To apply manually:
gh workflow run "Terraform Deployment" --ref main -f action=apply

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
- **State Locking**: `use_lockfile = true` (S3 lockfile, no DynamoDB table)
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
terraform init -backend-config=environments/prod/backend.conf -reconfigure
terraform plan -var-file=environments/prod/terraform.tfvars  # read-only preview
```

## Dev and Staging

| Environment | Site | State bucket | Status |
|---|---|---|---|
| dev | `dev.lawnsmartapp.com` | `lawnsmartapp-terraform-state-dev` | Bucket exists; not deployed by CI |
| staging | `staging.lawnsmartapp.com` | `lawnsmartapp-terraform-state-staging` | Bucket not created |

Create missing state buckets with `scripts/create-prerequisites.sh`. The local deployment scripts that used to target these environments are archived; see `archived/README.md`.

## Security Features

- ✅ **OIDC Authentication**: GitHub Actions uses AWS OIDC, no stored credentials
- ✅ **Repository Isolation**: IAM trust policy restricted to this specific repository
- ⚠️ **Least Privilege**: partial; only IAM and DynamoDB statements are scoped to project resources; S3, CloudFront, Route53 and ACM are account-wide
- ✅ **Audit Trail**: All deployments logged via GitHub Actions and CloudTrail
- ✅ **Encrypted State**: Terraform state encrypted at rest in S3