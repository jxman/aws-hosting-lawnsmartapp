# Archived Files

This directory contains files that are no longer part of the active project workflow.

## Local Deployment Scripts (Deprecated)

The files in `local-deployment-scripts/` were used for local Terraform deployments but have been **deprecated** in favor of GitHub Actions workflows.

### Why These Were Archived:

1. **Security**: GitHub Actions uses OIDC authentication instead of local AWS credentials
2. **Consistency**: All deployments go through the same CI/CD pipeline
3. **Audit Trail**: GitHub Actions provides complete deployment history
4. **Team Collaboration**: Deployments are visible to all team members
5. **Best Practices**: Infrastructure should be deployed through CI/CD, not local machines

### Archived Files:

- `deploy-prod.sh` - Production deployment script
- `deploy-dev.sh` - Development deployment script  
- `deploy-staging.sh` - Staging deployment script
- `deploy.sh` - Generic deployment script (it read `backend-configs/`, which has since been removed, so it no longer runs as-is)

## Terraform Modules (Retired)

- `terraform-modules/github-oidc/` - The OIDC provider, role and policy module. Retired on 2025-11-16 when OIDC moved to `scripts/bootstrap-oidc.sh`; see [docs/oidc-bootstrap-migration.md](../docs/oidc-bootstrap-migration.md)

## Current Deployment Method

**Use GitHub Actions workflows only:**

```bash
# A push to main plans and applies. To apply manually:
gh workflow run "Terraform Deployment" --ref main -f action=apply

# Monitor deployment
gh run list --limit 5
gh run view [RUN_ID]
```

## Recovery Instructions

If these scripts are ever needed for emergency recovery:

1. **DO NOT** use them for regular deployments
2. Ensure AWS credentials are properly configured
3. Understand that this bypasses all CI/CD safety checks
4. Document any emergency usage and follow up with proper GitHub Actions deployment