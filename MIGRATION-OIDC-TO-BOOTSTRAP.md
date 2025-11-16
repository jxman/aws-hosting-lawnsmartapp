# OIDC Migration: Terraform Module → Bootstrap Script

## Overview

This document provides step-by-step instructions for migrating GitHub Actions OIDC resources from Terraform management to bootstrap script management.

**Date:** 2025-01-16
**Project:** aws-hosting-lawnsmartapp
**Purpose:** Align OIDC management with organizational standard (matching synepho-s3cf-site pattern)

---

## Why This Migration?

### Before (Terraform-managed):
- OIDC Provider, IAM Role, IAM Policy managed by `modules/github-oidc/`
- Tags couldn't be updated due to `lifecycle { ignore_changes = [tags] }`
- Inconsistent with other projects (synepho-s3cf-site uses bootstrap script)

### After (Bootstrap-managed):
- OIDC resources created by `scripts/bootstrap-oidc.sh`
- Tags fully controllable and standardized
- Consistent pattern across all projects
- No Terraform state conflicts

---

## Pre-Migration Checklist

Before starting, verify:

- [ ] You have AWS CLI installed and configured
- [ ] You have appropriate AWS IAM permissions
- [ ] Current GitHub Actions workflows are working
- [ ] You have terraform installed
- [ ] You're on the main branch with latest changes

**Verify current OIDC resources exist:**

```bash
# Check OIDC Provider
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com

# Check IAM Role
aws iam get-role --role-name GithubActionsOIDC-LawnSmartApp-Role

# Check IAM Policy
aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/GithubActions-LawnSmartApp-Policy
```

All three commands should return results. **Document the ARNs for reference.**

---

## Migration Steps

### Step 1: Remove OIDC Resources from Terraform State

**CRITICAL:** This removes resources from Terraform state **WITHOUT deleting them from AWS**.

```bash
cd /Users/johxan/Documents/my-projects/lawnsmart-app/aws-hosting-lawnsmartapp

# Initialize Terraform
terraform init

# Remove OIDC module resources from state (does NOT delete from AWS)
terraform state rm module.github_oidc.aws_iam_openid_connect_provider.github_actions
terraform state rm module.github_oidc.aws_iam_role.github_actions_role
terraform state rm module.github_oidc.aws_iam_policy.github_actions_policy
terraform state rm module.github_oidc.aws_iam_role_policy_attachment.github_actions_policy_attachment
```

**Expected output:**
```
Removed module.github_oidc.aws_iam_openid_connect_provider.github_actions
Removed module.github_oidc.aws_iam_role.github_actions_role
Removed module.github_oidc.aws_iam_policy.github_actions_policy
Removed module.github_oidc.aws_iam_role_policy_attachment.github_actions_policy_attachment
```

**Verify removal:**
```bash
terraform state list | grep github_oidc
# Should return nothing
```

### Step 2: Verify AWS Resources Still Exist

```bash
# These should all still work (resources not deleted, just removed from Terraform state)
aws iam get-role --role-name GithubActionsOIDC-LawnSmartApp-Role --query 'Role.Arn'
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com
aws iam list-policies --scope Local | grep GithubActions-LawnSmartApp-Policy
```

**All commands should succeed.** If any fail, **STOP** and investigate before continuing.

### Step 3: Run Bootstrap Script to Update Tags

The bootstrap script will:
- Detect existing OIDC resources
- Update tags to match standardization (Owner, Project, SubService, etc.)
- **NOT recreate or delete anything**

```bash
# Make script executable (if not already)
chmod +x scripts/bootstrap-oidc.sh

# Run bootstrap script
bash scripts/bootstrap-oidc.sh
```

**Expected output:**
```
========================================
  GitHub Actions OIDC Bootstrap
  Project: LawnSmartApp
========================================

✓ AWS Account ID: XXXXXXXXXXXX
✓ GitHub Repository: jxman/aws-hosting-lawnsmartapp

Step 1: OIDC Provider
Checking if OIDC provider exists for https://token.actions.githubusercontent.com...
✓ OIDC provider already exists: arn:aws:iam::...
   Updating tags on existing OIDC provider...
✓ Tags updated on OIDC provider

Step 2: IAM Policy
Checking if policy GithubActions-LawnSmartApp-Policy exists...
✓ Policy already exists: arn:aws:iam::...
   Updating tags on existing policy...
✓ Tags updated on policy

Step 3: IAM Role
Checking if role GithubActionsOIDC-LawnSmartApp-Role exists...
✓ Role already exists: arn:aws:iam::...
   Updating tags on existing role...
✓ Tags updated on role
✓ Policy already attached to role

========================================
  Bootstrap Complete!
========================================

✓ OIDC Provider ARN:  arn:aws:iam::...
✓ IAM Role ARN:       arn:aws:iam::...
✓ IAM Policy ARN:     arn:aws:iam::...
```

### Step 4: Verify Updated Tags

```bash
# Check OIDC Provider tags
aws iam list-open-id-connect-provider-tags \
  --open-id-connect-provider-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com

# Check IAM Role tags
aws iam list-role-tags --role-name GithubActionsOIDC-LawnSmartApp-Role

# Check IAM Policy tags
aws iam list-policy-tags \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/GithubActions-LawnSmartApp-Policy
```

**Verify all resources have these tags:**
- `Environment = prod`
- `ManagedBy = terraform`
- `Owner = John Xanthopoulos`
- `Project = lawnsmartapp`
- `Service = lawnsmartapp-website`
- `GithubRepo = github.com/jxman/aws-hosting-lawnsmartapp`
- `Site = lawnsmartapp.com`
- `BaseProject = lawnsmartapp.com`
- `Name = <resource-specific>`
- `SubService = <github-oidc-provider | github-actions-role | github-actions-policy>`

### Step 5: Test Terraform Plan

```bash
# Verify Terraform no longer tries to manage OIDC resources
terraform plan

# Expected: No changes to OIDC resources
# Should only show changes to other resources (if any)
```

**If Terraform tries to create new OIDC resources:**
- ❌ **STOP** - Something went wrong
- Verify module was removed from main.tf
- Verify state was removed in Step 1

### Step 6: Test GitHub Actions Deployment

```bash
# Trigger a deployment to verify OIDC authentication still works
gh workflow run "Terraform Deployment" --ref main

# Monitor the run
gh run watch
```

**Expected:** Deployment succeeds with no OIDC authentication errors.

### Step 7: Commit Changes

```bash
# Stage changes
git add scripts/bootstrap-oidc.sh
git add main.tf
git add archived/terraform-modules/github-oidc/
git add MIGRATION-OIDC-TO-BOOTSTRAP.md
git add DEPLOYMENT_GUIDE.md
git add CLAUDE.md

# Commit
git commit -m "refactor: migrate OIDC management from Terraform to bootstrap script

Align OIDC resource management with organizational standard.

Changes:
- Create scripts/bootstrap-oidc.sh for OIDC management
- Remove modules/github-oidc/ (archived)
- Update main.tf to reference bootstrap script
- Update all OIDC resource tags to match standardization
- Add migration documentation

Benefits:
- Consistent OIDC management across all projects
- Full tag control (no lifecycle ignore_changes conflicts)
- Simplified Terraform state management
- Idempotent bootstrap script for easy setup

Migration completed following MIGRATION-OIDC-TO-BOOTSTRAP.md instructions.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
"

# Push to origin
git push origin main
```

---

## Rollback Plan

If something goes wrong, you can restore the Terraform module:

```bash
# Restore archived module
mv archived/terraform-modules/github-oidc modules/

# Restore main.tf module call
git checkout HEAD~1 -- main.tf

# Import resources back into Terraform state
terraform import 'module.github_oidc.aws_iam_openid_connect_provider.github_actions' \
  arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com

terraform import 'module.github_oidc.aws_iam_role.github_actions_role' \
  GithubActionsOIDC-LawnSmartApp-Role

terraform import 'module.github_oidc.aws_iam_policy.github_actions_policy' \
  arn:aws:iam::ACCOUNT_ID:policy/GithubActions-LawnSmartApp-Policy

terraform import 'module.github_oidc.aws_iam_role_policy_attachment.github_actions_policy_attachment' \
  GithubActionsOIDC-LawnSmartApp-Role/arn:aws:iam::ACCOUNT_ID:policy/GithubActions-LawnSmartApp-Policy
```

---

## Post-Migration Verification

After migration, verify:

- [ ] OIDC resources exist in AWS with correct tags
- [ ] Terraform state does NOT include OIDC resources
- [ ] GitHub Actions workflows deploy successfully
- [ ] Documentation updated (DEPLOYMENT_GUIDE.md, CLAUDE.md)
- [ ] Team members aware of new OIDC management process

---

## FAQ

### Q: Will this affect existing GitHub Actions workflows?
**A:** No. The OIDC resources remain unchanged in AWS. Only the management method changes.

### Q: Can I run the bootstrap script multiple times?
**A:** Yes. The script is idempotent and safe to re-run. It will update tags without recreating resources.

### Q: What if I need to update IAM permissions later?
**A:** Update the policy document in `scripts/bootstrap-oidc.sh` and re-run the script. It will create a new policy version.

### Q: Why remove from Terraform instead of importing into bootstrap?
**A:** Bootstrap scripts create resources outside Terraform. Terraform can't manage what it didn't create via code.

### Q: What happens if I run terraform destroy?
**A:** Terraform won't try to destroy OIDC resources since they're no longer in state. Bootstrap resources persist.

---

## Support

If you encounter issues during migration:

1. Check the rollback plan above
2. Verify AWS CLI credentials are correct
3. Ensure you have necessary IAM permissions
4. Review GitHub Actions workflow logs
5. Check Terraform state: `terraform state list`

---

**Migration Author:** Claude Code
**Date:** 2025-01-16
**Status:** Ready for execution
