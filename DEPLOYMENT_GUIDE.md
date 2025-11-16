# 🚀 GitHub Actions Deployment Guide

**🔐 Security Policy: All infrastructure deployments for LawnSmartApp MUST use GitHub Actions workflows with OIDC authentication.**

This guide covers the secure, standardized deployment process using GitHub Actions for the LawnSmart App AWS hosting infrastructure.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Monitoring Deployments](#monitoring-deployments)
- [Security Implementation](#security-implementation)
- [Troubleshooting](#troubleshooting)
- [Emergency Procedures](#emergency-procedures)

## ⚡ Quick Start

### Prerequisites
- **GitHub CLI** (`gh`) installed and authenticated
- **Push access** to the repository
- **GitHub repository** properly configured with OIDC

### Deploy Infrastructure
```bash
# Deploy infrastructure changes
gh workflow run "Terraform Deployment" --ref main

# Monitor deployment status
gh run list --limit 5

# View detailed deployment logs
gh run view [RUN_ID] --web
```

## 🔄 GitHub Actions Workflow

### Workflow Overview

The GitHub Actions workflow (`terraform.yml`) provides:
- ✅ **OIDC Authentication**: Secure AWS access without stored credentials
- ✅ **Terraform Operations**: Plan, apply, and output generation
- ✅ **Security Validation**: Resource compliance and security checks
- ✅ **CloudFront Invalidation**: Automatic cache clearing after deployment
- ✅ **Deployment Logging**: Complete audit trail

### Workflow Triggers

| Trigger | Description | Environment |
|---------|-------------|-------------|
| **Push to main** | Automatic deployment | Production |
| **Manual dispatch** | On-demand deployment | Production |
| **Pull request** | Plan-only (validation) | Preview |

### Deployment Process

#### 1. **Automatic Deployment (Recommended)**
```bash
# Make infrastructure changes
git add .
git commit -m "feat: update CloudFront configuration"
git push origin main

# ✅ Automatically triggers deployment workflow
```

#### 2. **Manual Deployment**
```bash
# Trigger deployment manually
gh workflow run "Terraform Deployment" --ref main

# Alternative: Use GitHub web interface
# 1. Go to https://github.com/jxman/aws-hosting-lawnsmartapp/actions
# 2. Click "Terraform Deployment" → "Run workflow"
# 3. Select branch "main" → "Run workflow"
```

#### 3. **Monitoring Deployment**
```bash
# Check recent runs
gh run list --limit 10

# View specific deployment
gh run view [RUN_ID]

# Open deployment in browser
gh run view [RUN_ID] --web

# Watch real-time logs
gh run watch [RUN_ID]
```

## 📊 Monitoring Deployments

### Real-Time Monitoring Commands

```bash
# List recent workflow runs
gh run list --limit 5

# Filter by status
gh run list --status completed --limit 10
gh run list --status failure --limit 5
gh run list --status in_progress --limit 3

# View specific run details
gh run view [RUN_ID]

# Download logs locally
gh run download [RUN_ID]

# Watch live deployment
gh run watch [RUN_ID]
```

### Deployment Status Indicators

| Status | Description | Action Required |
|--------|-------------|-----------------|
| ✅ **Success** | Deployment completed successfully | None |
| 🔄 **In Progress** | Deployment currently running | Monitor |
| ❌ **Failure** | Deployment failed | Investigate logs |
| ⏸️ **Cancelled** | Deployment was cancelled | Re-run if needed |
| ⏳ **Queued** | Deployment waiting to start | Wait |

### Key Deployment Outputs

After successful deployment, check for these outputs:
- **Website URL**: `https://lawnsmartapp.com`
- **CloudFront Distribution ID**: For cache invalidation
- **S3 Bucket Names**: For application deployment
- **Certificate ARN**: SSL certificate details
- **Route53 Zone ID**: DNS configuration

## 🛡️ Security Implementation

### OIDC Authentication

The deployment uses **OpenID Connect (OIDC)** for secure AWS authentication:

#### Security Features
- 🔐 **No Stored Credentials**: No AWS access keys in GitHub secrets
- 🏢 **Repository Isolation**: Only this repository can assume the role
- ⏰ **Short-Lived Tokens**: Temporary credentials per deployment
- 📝 **Complete Audit Trail**: All deployments logged in CloudTrail
- 🔒 **Least Privilege**: IAM permissions scoped to required resources

#### IAM Resources (Managed by Bootstrap Script)
- **Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **Policy**: `GithubActions-LawnSmartApp-Policy`
- **Trust Policy**: Restricted to `jxman/aws-hosting-lawnsmartapp` repository
- **OIDC Provider**: `token.actions.githubusercontent.com`

**IMPORTANT:** OIDC resources are managed by `scripts/bootstrap-oidc.sh`, NOT by Terraform. This ensures:
- Consistent OIDC management across all projects
- Full control over resource tags
- No Terraform state conflicts with authentication infrastructure

#### Initial OIDC Setup (One-Time)

If setting up a new environment or updating OIDC resources:

```bash
# Run bootstrap script (idempotent - safe to run multiple times)
bash scripts/bootstrap-oidc.sh
```

The script will:
- Create OIDC provider if it doesn't exist
- Create IAM role and policy if they don't exist
- Update tags to match organizational standards
- Verify all resources are properly configured

**See:** `MIGRATION-OIDC-TO-BOOTSTRAP.md` for details on the bootstrap approach.

### Deployment Security Checks

The workflow includes automated security validation:
- ✅ **Terraform Plan Review**: All changes reviewed before apply
- ✅ **Resource Compliance**: S3 bucket policies and CloudFront settings
- ✅ **Certificate Validation**: SSL/TLS certificate status
- ✅ **DNS Configuration**: Route53 record validation
- ✅ **IAM Policy Review**: Role and policy compliance

## 🔧 Troubleshooting

### Common Issues and Solutions

#### **❌ Workflow Fails with Authentication Error**
```
Error: Could not assume role with OIDC
```

**Solution:**
1. Verify repository name in IAM trust policy
2. Check OIDC provider configuration
3. Ensure workflow is running from `main` branch

#### **❌ Terraform Plan Shows Unexpected Changes**
```
Terraform detected drift in resources
```

**Solution:**
1. Review what changed outside Terraform
2. Import resources if needed: `terraform import [resource] [id]`
3. Update configuration to match current state

#### **❌ CloudFront Distribution Update Fails**
```
Error: Distribution is still deploying
```

**Solution:**
1. Wait for previous CloudFront deployment to complete
2. Check distribution status in AWS console
3. Re-run workflow after deployment completes

#### **❌ DNS Records Not Updating**
```
Route53 records not resolving
```

**Solution:**
1. Check Route53 hosted zone configuration
2. Verify ACM certificate validation status
3. Test DNS propagation: `dig lawnsmartapp.com`

### Debugging Commands

```bash
# Check workflow run logs
gh run view [RUN_ID] --log

# Download all logs for offline analysis
gh run download [RUN_ID]

# Check recent failures
gh run list --status failure --limit 5

# View specific job logs
gh run view [RUN_ID] --log --job="terraform-deploy"
```

### AWS Resource Verification

```bash
# Verify infrastructure state
aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`lawnsmartapp.com CloudFront`]'

# Check S3 buckets
aws s3 ls | grep lawnsmartapp

# Verify Route53 records
aws route53 list-resource-record-sets --hosted-zone-id Z04860973DG1BJ5J1VVBE

# Check ACM certificates
aws acm list-certificates --certificate-statuses ISSUED
```

## 🚨 Emergency Procedures

### Emergency Rollback

#### **Method 1: Git Rollback + Redeploy**
```bash
# Find last working commit
git log --oneline -10

# Rollback to working state
git checkout [WORKING_COMMIT_HASH]
git checkout -b emergency-rollback
git push origin emergency-rollback

# Deploy from rollback branch
gh workflow run "Terraform Deployment" --ref emergency-rollback
```

#### **Method 2: Re-run Previous Successful Deployment**
```bash
# Find last successful deployment
gh run list --status completed --limit 5

# Re-run the successful deployment
gh run rerun [SUCCESSFUL_RUN_ID]
```

### Emergency Contact Procedures

1. **Infrastructure Issues**: Check AWS Service Health Dashboard
2. **DNS Issues**: Verify Route53 and domain registrar settings
3. **Certificate Issues**: Check ACM certificate status and validation
4. **GitHub Actions Issues**: Check GitHub Status page

### Manual Infrastructure Recovery

**⚠️ Only use in extreme emergencies when GitHub Actions is unavailable:**

```bash
# This bypasses all CI/CD safety checks - use with extreme caution
# Ensure proper AWS credentials are configured
terraform init
terraform plan
# Review plan carefully before applying
terraform apply
```

## 📈 Performance and Optimization

### Deployment Performance Metrics

- **Average Deployment Time**: 3-5 minutes
- **Terraform Plan**: 30-60 seconds
- **Terraform Apply**: 2-3 minutes
- **CloudFront Propagation**: 15-20 minutes (global)

### Optimization Tips

1. **Use Specific Commits**: Reference specific commit SHAs for deterministic deployments
2. **Monitor Resource Limits**: Check AWS service quotas
3. **Plan Before Apply**: Always review Terraform plans
4. **Staged Rollouts**: Use CloudFront cache invalidation strategically

## 📚 References

- **GitHub Actions Documentation**: [GitHub Actions Docs](https://docs.github.com/en/actions)
- **AWS OIDC Configuration**: [AWS IAM OIDC Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- **Terraform AWS Provider**: [Terraform AWS Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **AWS Well-Architected**: [AWS Architecture Framework](https://aws.amazon.com/architecture/well-architected/)

---

**🌱 LawnSmart App - Secure Infrastructure Deployment**  
*Deployed with confidence using GitHub Actions + AWS OIDC + Terraform*