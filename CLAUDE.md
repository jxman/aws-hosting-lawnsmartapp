# AWS Hosting LawnSmartApp - Project Instructions

This file contains project-specific instructions for the LawnSmartApp AWS hosting infrastructure.

## Deployment Policy - GitHub Actions Only

**CRITICAL: All infrastructure deployments MUST use GitHub Actions workflows. Local deployment scripts are DEPRECATED and archived.**

### Required Deployment Method

```bash
# A push to main that changes **.tf or the workflow plans AND applies
git push origin main

# Manual run: action defaults to plan; pass action=apply to deploy
gh workflow run "Terraform Deployment" --ref main -f action=apply

# Monitor deployment progress
gh run list --limit 5
gh run view [RUN_ID]

# View deployment in browser
gh run view [RUN_ID] --web
```

### Why GitHub Actions is Mandatory

- **Security**: Uses OIDC authentication instead of local AWS credentials
- **Audit Trail**: Complete deployment history and logging
- **Consistency**: Standardized deployment environment
- **Team Visibility**: All deployments tracked and visible
- **Best Practices**: Infrastructure deployed through CI/CD, never from local machines

### Terraform Commands (Development/Testing Only)

For local development and testing (NOT deployment):
- **Lint/Format**: `terraform fmt -recursive`
- **Validate**: `terraform validate`
- **Plan** (read-only): `terraform init -backend-config=environments/prod/backend.conf -reconfigure` then `terraform plan -var-file=environments/prod/terraform.tfvars` (requires AWS credentials)
- Don't run a local plan while a CI run is in progress: both take the S3 lockfile on the same state

### Local Scripts Status

- ❌ **deploy-prod.sh**: DEPRECATED - moved to `archived/local-deployment-scripts/`
- ❌ **deploy-dev.sh**: DEPRECATED - moved to `archived/local-deployment-scripts/`
- ❌ **deploy-staging.sh**: DEPRECATED - moved to `archived/local-deployment-scripts/`
- ✅ **GitHub Actions**: REQUIRED for all deployments

## GitHub Actions OIDC Security Implementation

This project implements **best-practice OIDC authentication** with complete repository isolation.

### Project-Specific IAM Resources

- **IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **IAM Policy**: `GithubActions-LawnSmartApp-Policy`
- **Repository Restriction**: Only `jxman/aws-hosting-lawnsmartapp` can assume the role
- **OIDC Provider**: Project-specific with official GitHub thumbprints

### Security Features

- ✅ **Repository isolation**: Trust policy restricted to this specific repository
- ⚠️ **Least privilege**: partial (see Resource restrictions)
- ✅ **Project-specific naming**: No conflicts with other repositories
- ⚠️ **Resource restrictions**: only the IAM and DynamoDB statements are scoped to project ARNs; `s3:*`, `cloudfront:*`, `route53:*`, `acm:*`, `cloudwatch:*` and `logs:*` are granted on all resources. Scoping them is on the README roadmap
- ✅ **No long-lived credentials**: Uses OIDC web identity federation

### Implementation Status

- ✅ **OIDC Infrastructure**: Fully deployed and operational
- ✅ **GitHub Actions Integration**: Successfully tested and working
- ✅ **Repository Isolation**: Verified and secure
- ⚠️ **Permission Model**: Working, but broader than least privilege (see above)

### Key Resources Created

- **IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **IAM Policy**: `GithubActions-LawnSmartApp-Policy`
- **OIDC Provider**: `token.actions.githubusercontent.com`
- **Managed by**: `scripts/bootstrap-oidc.sh` (not Terraform; the old module is in `archived/terraform-modules/github-oidc/`)
- **Documentation**: See `docs/deployment-guide.md` and `docs/oidc-bootstrap-migration.md`

## Monitoring Standards

- **Always include monitoring** when adding new AWS services
- **CloudWatch dashboards** should show regional traffic patterns
- **Set up alarms** for critical metrics (error rates >5%, cache hit <80%, latency >1000ms)
- **Use consistent naming** for metrics and alarms: `${site_name}-metric-description`

## Project Structure Requirements

- **All modules** must have versions.tf, variables.tf, outputs.tf, and main.tf
- **Environment isolation** - each environment has its own state and configuration
- **Output important values** like dashboard URLs and distribution IDs for operational use
- **OIDC resources** are managed by `scripts/bootstrap-oidc.sh`, outside Terraform state
- **Docs**: README describes the current system; history goes in `CHANGELOG.md`; longer guides and runbooks go in `docs/`

## Security Requirements

- **Never expose S3 buckets** publicly - always use CloudFront Origin Access Control
- **Enable logging** for all components (S3, CloudFront access logs)
- **Use least privilege IAM** policies for all service roles
- **Enable encryption** for all data at rest (S3, logs)
- **Project-specific IAM roles** for GitHub Actions with repository isolation
- **OIDC authentication** instead of long-lived AWS credentials
- **Trust policy restrictions** to prevent cross-repository access

## Testing Requirements

- **Update tests after making code changes** that require test updates
- **Always run tests** before deploying infrastructure changes
- **Validate Terraform** configurations before commit
