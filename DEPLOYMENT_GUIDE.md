# 🔐 OIDC Security Upgrade Deployment Guide

## Overview
This guide covers deploying the new project-specific OIDC authentication system that replaces the generic GitHub Actions role with a secure, isolated setup.

## 🚨 Important: Deployment Order

### Step 1: Deploy OIDC Infrastructure (One-time)
Since GitHub Actions currently uses the old generic role, we need to deploy the new OIDC infrastructure first:

```bash
# Deploy to development first
./deploy-dev.sh plan
./deploy-dev.sh apply

# Then deploy to production
./deploy-prod.sh plan
./deploy-prod.sh apply
```

### Step 2: Verify New Role Creation
After deployment, verify the new role was created:

```bash
# Check the new role exists
aws iam get-role --role-name GithubActionsOIDC-LawnSmartApp-Role

# Get the role ARN (should match what's in the workflow)
terraform output github_actions_role_arn
```

### Step 3: Test GitHub Actions
The workflow will now use the new project-specific role automatically. Test by:

1. **Push to main** (triggers dev deployment)
2. **Create PR** (triggers plan-only)
3. **Manual production deployment** via GitHub UI

## 🔄 What Changed

### New OIDC Module (`modules/github-oidc/`)
- **Project-specific naming**: `GithubActionsOIDC-LawnSmartApp-Role`
- **Repository restriction**: Only `jxman/aws-hosting-lawnsmartapp`
- **Least privilege permissions**: Scoped to project resources only
- **Official GitHub thumbprints**: Latest OIDC provider configuration

### Updated Workflow
- **Role ARN**: `arn:aws:iam::600424110307:role/GithubActionsOIDC-LawnSmartApp-Role`
- **Same functionality**: All existing deployment capabilities preserved
- **Enhanced security**: Repository isolation and least privilege

### Enhanced Documentation
- **CLAUDE.md**: Updated with project-specific OIDC requirements
- **Security standards**: Documented best practices implementation

## 🛡️ Security Improvements

### Before (Insecure)
```yaml
# Generic role - any repo could potentially use
role-to-assume: arn:aws:iam::ACCOUNT:role/GithubActionsOIDCTerraformRole
```

### After (Secure)
```yaml
# Project-specific role with repository restrictions
role-to-assume: arn:aws:iam::ACCOUNT:role/GithubActionsOIDC-LawnSmartApp-Role
```

### Trust Policy Restrictions
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:jxman/aws-hosting-lawnsmartapp:*"
  }
}
```

## 🔍 Validation

### Verify Role Permissions
```bash
# Check role trust policy
aws iam get-role --role-name GithubActionsOIDC-LawnSmartApp-Role --query 'Role.AssumeRolePolicyDocument'

# Check attached policies
aws iam list-attached-role-policies --role-name GithubActionsOIDC-LawnSmartApp-Role
```

### Test Repository Isolation
The role should ONLY be assumable by `jxman/aws-hosting-lawnsmartapp`. Any other repository attempting to use this role will be denied.

### Verify Resource Restrictions
IAM permissions are scoped to:
- S3 buckets containing `lawnsmartapp` in the name
- DynamoDB tables with `terraform` and `lock` in the name
- Project-specific CloudFront, Route53, and ACM resources

## 🚀 Rollback Plan (If Needed)

If issues occur, temporarily revert the workflow:

```yaml
# Temporary rollback to old role
role-to-assume: arn:aws:iam::600424110307:role/GithubActionsOIDCTerraformRole
```

Then investigate and fix the new role configuration.

## ✅ Success Criteria

1. ✅ New OIDC module deploys successfully
2. ✅ GitHub Actions workflows continue to work
3. ✅ Role is restricted to this repository only
4. ✅ IAM permissions follow least privilege principle
5. ✅ No conflicts with other repositories

## 📞 Support

If deployment issues occur:
1. Check AWS IAM console for role creation
2. Verify GitHub Actions logs for authentication errors
3. Review Terraform outputs for correct ARNs
4. Confirm repository name matches trust policy

---
**🔐 Security upgrade complete - your infrastructure now follows OIDC best practices!**