# 🌱 AWS Hosting Infrastructure for LawnSmart App

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/aws-hosting-lawnsmartapp/terraform.yml?branch=main&style=for-the-badge)

This repository contains Infrastructure as Code (IaC) for deploying a production-ready React application hosting solution on AWS. Specifically designed for the LawnSmart App - a smart lawn care management application.

**🔐 Security Policy: All infrastructure deployments MUST use GitHub Actions workflows with OIDC authentication.**

## 🚀 Live Production Site

**Production:** [https://lawnsmartapp.com](https://lawnsmartapp.com) *(Production Environment)*  
**Production (www):** [https://www.lawnsmartapp.com](https://www.lawnsmartapp.com) *(Redirects to main domain)*

### Current Production Status
- **Domain:** `lawnsmartapp.com`
- **CloudFront Distribution:** `E1MYY1CD3E7WBQ` (Active)
- **SSL Certificate:** `arn:aws:acm:us-east-1:600424110307:certificate/08e59308-3109-4531-9895-c4d77ba3636c`
- **Primary S3 Bucket:** `www.lawnsmartapp.com`
- **Failover S3 Bucket:** `prod-lawnsmartapp-secondary`
- **Status:** ✅ **Deployed & Active**

## 🏗️ Production Architecture

The infrastructure implements **enterprise-grade AWS hosting** with high availability and security:

### Core Components
- **🌐 Multi-Region Setup**: Primary (us-east-1) + Failover (us-west-1)
- **⚡ CloudFront CDN**: Global edge caching with custom domains
- **🔒 SSL/TLS**: Auto-managed certificates with Route53 validation
- **📱 React SPA Support**: Proper routing configuration (404→index.html)
- **🛡️ Security Headers**: CSP, HSTS, X-Frame-Options, etc.
- **📊 Access Logging**: Centralized logging for monitoring
- **🔄 Auto-Replication**: Cross-region S3 replication for resilience
- **🔐 OIDC Security**: GitHub Actions authentication via AWS OIDC

### Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Route53 DNS  │───▶│  CloudFront CDN │───▶│ Primary S3      │
│ (lawnsmartapp   │    │ (Global Edge    │    │ (us-east-1)     │
│  .com)          │    │  Locations)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       ▼
        │                       │               ┌─────────────────┐
        │                       └──────────────▶│ Failover S3     │
        │                                       │ (us-west-1)     │
        │                                       │                 │
        ▼                                       └─────────────────┘
┌─────────────────┐                           ┌─────────────────┐
│ GitHub Actions  │                           │ AWS OIDC        │
│ CI/CD Pipeline  │◀─────────────────────────▶│ Authentication  │
│ (Secure Deploy) │                           │ (No Stored Keys)│
└─────────────────┘                           └─────────────────┘
```

## 🛠️ Prerequisites

- **Git** for version control
- **GitHub CLI** (`gh`) for deployment management
- **AWS CLI** (optional, for local testing only)
- **Terraform** >= 1.7.0 (optional, for local validation only)

## ⚡ Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/jxman/aws-hosting-lawnsmartapp.git
cd aws-hosting-lawnsmartapp
```

### 2. Deploy via GitHub Actions (REQUIRED)

**🔐 All deployments MUST use GitHub Actions workflows for security and consistency:**

```bash
# Deploy infrastructure changes
gh workflow run "Terraform Deployment" --ref main

# Monitor deployment progress
gh run list --limit 5
gh run view [RUN_ID]

# View deployment in browser
gh run view [RUN_ID] --web
```

### 3. Local Development (Read-Only)
```bash
# For development and testing only (NO deployment)
terraform fmt -recursive      # Format code
terraform validate           # Validate configuration
terraform plan              # Preview changes (requires AWS credentials)
```

## 📁 Project Structure

```
📦 aws-hosting-lawnsmartapp/
├── 🏗️ modules/                    # Reusable Terraform modules
│   ├── acm-certificate/           # SSL/TLS certificate management
│   ├── cloudfront/               # CDN + security headers
│   ├── github-oidc/              # OIDC authentication for GitHub Actions
│   ├── route53/                  # DNS management
│   └── s3-website/               # S3 hosting + replication
├── 🌍 environments/              # Environment-specific configs
│   └── prod/                     # Production configuration
│       ├── backend.conf          # Terraform state backend
│       └── terraform.tfvars     # Production variables
├── 📦 archived/                  # Deprecated local deployment scripts
│   ├── local-deployment-scripts/ # DEPRECATED: Local scripts
│   └── README.md                 # Why these were archived
├── 🚀 .github/workflows/         # CI/CD Pipeline
│   └── terraform.yml             # GitHub Actions workflow
├── 📋 main.tf                    # Main infrastructure
├── 📊 outputs.tf                 # Infrastructure outputs
├── 🔧 variables.tf               # Input variables
├── 📌 versions.tf                # Provider constraints
└── 📖 README.md                  # This file
```

## 🔄 GitHub Actions Deployment Workflow

### Deployment Policy: GitHub Actions Only

**🔐 CRITICAL: All infrastructure deployments MUST use GitHub Actions workflows. Local deployment scripts are DEPRECATED and archived.**

### 🚀 Deployment Methods

#### GitHub Actions (REQUIRED)

**🔐 Security Policy: All infrastructure deployments MUST use GitHub Actions workflows.**

```bash
# Deploy infrastructure changes
gh workflow run "Terraform Deployment" --ref main

# Monitor deployment status
gh run list --limit 5
gh run view [RUN_ID]

# View deployment in browser
gh run view [RUN_ID] --web
```

#### GitHub UI Alternative
1. **Navigate to** [GitHub Actions](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)
2. **Click** "Terraform Deployment" workflow → "Run workflow"
3. **Branch:** Select `main`
4. **Click** "Run workflow"

#### Why GitHub Actions Only?
- ✅ **OIDC Authentication**: Secure, no stored AWS credentials
- ✅ **Audit Trail**: Complete deployment history
- ✅ **Consistency**: Standardized deployment environment
- ✅ **Team Visibility**: All deployments tracked and visible
- ✅ **Best Practices**: Infrastructure deployed through CI/CD

### 🔄 Development Workflow

#### 1. **Feature Development**
```bash
# Make infrastructure changes
vim modules/cloudfront/main.tf

# Test locally (read-only)
terraform fmt -recursive
terraform validate

# Commit and push (triggers GitHub Actions deployment)
git add . && git commit -m "feat: add new infrastructure"
git push origin main
# ✅ Triggers GitHub Actions workflow for production deployment
```

#### 2. **Monitor Deployment**
```bash
# Check deployment status
gh run list --limit 5

# View specific deployment
gh run view [RUN_ID]

# Watch deployment logs in real-time
gh run view [RUN_ID] --web
```

#### 3. **Manual Deployment Trigger**
```bash
# Manually trigger deployment if needed
gh workflow run "Terraform Deployment" --ref main

# Monitor the triggered deployment
gh run list --limit 1
```

## 🛡️ Security & OIDC Implementation

### GitHub Actions OIDC Security Implementation
This project implements **best-practice OIDC authentication** with complete repository isolation:

#### Project-Specific IAM Resources
- **IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **IAM Policy**: `GithubActions-LawnSmartApp-Policy`
- **Repository Restriction**: Only `jxman/aws-hosting-lawnsmartapp` can assume the role
- **OIDC Provider**: Project-specific with official GitHub thumbprints

#### Security Features
- ✅ **Repository isolation**: Trust policy restricted to this specific repository
- ✅ **Least privilege**: IAM permissions scoped to only required resources
- ✅ **Project-specific naming**: No conflicts with other repositories
- ✅ **Resource restrictions**: S3/DynamoDB permissions limited to project buckets
- ✅ **No long-lived credentials**: Uses OIDC web identity federation

#### Implementation Status
- ✅ **OIDC Infrastructure**: Fully deployed and operational
- ✅ **GitHub Actions Integration**: Successfully tested and working
- ✅ **Repository Isolation**: Verified and secure
- ✅ **Permission Model**: Complete with least privilege access

#### OIDC Resources Management
- **IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- **IAM Policy**: `GithubActions-LawnSmartApp-Policy`
- **OIDC Provider**: `token.actions.githubusercontent.com`
- **Managed By**: `scripts/bootstrap-oidc.sh` (NOT Terraform)

**To update OIDC resources or tags:**
```bash
bash scripts/bootstrap-oidc.sh
```

See `MIGRATION-OIDC-TO-BOOTSTRAP.md` for details on the bootstrap approach.

### Production Resources
- **S3 Buckets:** `lawnsmartapp.com-site-logs`, `www.lawnsmartapp.com`, `prod-lawnsmartapp-secondary`
- **IAM Roles:** `prod-lawnsmartapp-replication-role`
- **CloudFront:** `prod-lawnsmartapp-com-oac`
- **Domain:** `lawnsmartapp.com`

### Security Implementation
- ✅ **Project-Specific IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- ✅ **Resource Isolation**: Complete separation prevents conflicts
- ✅ **OIDC Authentication**: No stored AWS credentials in GitHub
- ✅ **Least Privilege Permissions**: IAM policies scoped to project resources
- ✅ **State Encryption**: AES256 encryption for all Terraform state
- ✅ **Origin Access Control**: S3 buckets only accessible via CloudFront

## 🏷️ AWS Resource Tagging Standard

All AWS resources follow organizational tagging standards for cost tracking, resource management, and compliance.

### Standard Tags (Applied to All Resources)

| Tag Key | Tag Value | Purpose |
|---------|-----------|---------|
| `Environment` | `prod`, `staging`, `dev` | Environment identification |
| `ManagedBy` | `terraform` or `bootstrap-script` | Management method |
| `Owner` | `John Xanthopoulos` | Resource owner |
| `Project` | `lawnsmartapp` | Project identifier |
| `Service` | `lawnsmartapp-website` | Service name |
| `GithubRepo` | `github.com/jxman/aws-hosting-lawnsmartapp` | Source repository |
| `Site` | `lawnsmartapp.com` | Website domain |
| `BaseProject` | `lawnsmartapp.com` | Base project domain |
| `Name` | `<resource-specific>` | Resource name |
| `SubService` | `<component-specific>` | Component identifier |

### Resource-Specific SubService Tags

| AWS Resource | SubService Value | Managed By |
|--------------|------------------|------------|
| **S3 Primary Bucket** | `primary-website-bucket` | `terraform` |
| **S3 Failover Bucket** | `failover-website-bucket` | `terraform` |
| **S3 Logs Bucket** | `access-logs-bucket` | `terraform` |
| **CloudFront Distribution** | `cdn-distribution` | `terraform` |
| **ACM Certificate** | `ssl-certificate` | `terraform` |
| **IAM Replication Role** | `s3-replication-role` | `terraform` |
| **IAM Replication Policy** | `s3-replication-policy` | `terraform` |
| **OIDC Provider** | `github-oidc-provider` | `bootstrap-script` |
| **GitHub Actions IAM Role** | `github-actions-role` | `bootstrap-script` |
| **GitHub Actions IAM Policy** | `github-actions-policy` | `bootstrap-script` |

### Tag Management by Resource Type

#### Infrastructure Resources (Terraform-Managed)
Resources managed by Terraform deployments have `ManagedBy = terraform`:
- S3 buckets (website, logs, failover)
- CloudFront distributions
- ACM certificates
- Route53 DNS records
- IAM roles/policies for application infrastructure

**To update tags**: Deploy via GitHub Actions workflow

#### Authentication Resources (Bootstrap Script-Managed)
OIDC authentication resources have `ManagedBy = bootstrap-script`:
- OIDC Provider
- GitHub Actions IAM Role
- GitHub Actions IAM Policy

**To update tags**: Run `bash scripts/bootstrap-oidc.sh`

### Tag Benefits

✅ **Cost Allocation**: Track spending by project, environment, and service
✅ **Resource Discovery**: Filter and search resources by tags
✅ **Compliance**: Meet organizational tagging requirements
✅ **Operational Clarity**: Know how each resource is managed
✅ **Automation**: Enable tag-based policies and automation

### Querying Resources by Tags

```bash
# Find all resources for this project
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=lawnsmartapp

# Find all production environment resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=prod Key=Project,Values=lawnsmartapp

# Find all Terraform-managed resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=ManagedBy,Values=terraform Key=Project,Values=lawnsmartapp

# Find all bootstrap-managed resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=ManagedBy,Values=bootstrap-script
```

## 📱 React SPA Configuration

Optimized for React applications:

### Custom Error Handling
```terraform
custom_error_response {
  error_caching_min_ttl = 5
  error_code            = 403
  response_code         = 200
  response_page_path    = "/index.html"  # Enables client-side routing
}
```

### Application Deployment
```bash
# Build your React app
npm run build

# Deploy application to production
aws s3 sync build/ s3://www.lawnsmartapp.com/ --delete

# Invalidate CloudFront cache (get distribution ID from GitHub Actions output)
aws cloudfront create-invalidation --distribution-id [DISTRIBUTION_ID] --paths "/*"
```

## 📊 Infrastructure Outputs

View infrastructure outputs:

```bash
# View outputs from GitHub Actions logs
gh run view [RUN_ID] --web

# Or check outputs locally (requires AWS credentials)
terraform output
```

**Sample Production Outputs:**
- **website_url**: `https://lawnsmartapp.com`
- **cloudfront_distribution_id**: `E1MYY1CD3E7WBQ`
- **cloudfront_domain_name**: `d1yvxqir7ibuig.cloudfront.net`
- **certificate_arn**: `arn:aws:acm:us-east-1:600424110307:certificate/08e59308-3109-4531-9895-c4d77ba3636c`
- **primary_s3_bucket**: `www.lawnsmartapp.com`
- **failover_s3_bucket**: `prod-lawnsmartapp-secondary`

## 🔍 Troubleshooting & Operations

### Infrastructure Debugging

**Check Infrastructure State:**
```bash
# View deployment status
gh run list --limit 10

# Check infrastructure state (requires AWS credentials)
terraform init
terraform state list

# View infrastructure outputs
terraform output
```

**DNS Resolution Testing:**
```bash
# Test production domain
dig lawnsmartapp.com
dig www.lawnsmartapp.com

# Test CloudFront endpoint
curl -I https://lawnsmartapp.com
curl -I https://www.lawnsmartapp.com
```

**State Lock Issues:**
```bash
# Check for a lock file next to the state file
aws s3 ls s3://lawnsmartapp-terraform-state/lawnsmartapp-com/

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Emergency Procedures

**Infrastructure Rollback:**
```bash
# Method 1: Git rollback + redeploy
git checkout <previous-working-commit>
gh workflow run "Terraform Deployment" --ref main

# Method 2: GitHub Actions rollback
# Use the GitHub UI to re-run a previous successful workflow
```

**Resource Verification:**
```bash
# Check deployed resources
aws s3 ls | grep lawnsmartapp                    # Production buckets
aws iam list-roles | grep lawnsmartapp          # IAM roles  
aws cloudfront list-distributions | grep lawnsmartapp  # CloudFront distributions
```

## 🧪 Testing & Validation

### Infrastructure Testing
```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Test deployment preview (requires AWS credentials)
terraform plan
```

### Infrastructure Connectivity Testing
```bash
# Test production deployment
curl -I https://lawnsmartapp.com
curl -I https://www.lawnsmartapp.com

# Check security headers
curl -I https://lawnsmartapp.com | grep -E "(Strict-Transport|X-Frame|Content-Security)"
```

## 📋 Quick Reference

### 🚀 **Common Operations**

| Task | Command | Notes |
|------|---------|-------|
| **Deploy infrastructure** | `gh workflow run "Terraform Deployment" --ref main` | Required method |
| **Monitor deployment** | `gh run list --limit 5` | Check status |
| **View deployment** | `gh run view [RUN_ID] --web` | Detailed logs |
| **Preview changes** | `terraform plan` | Local only (requires AWS creds) |
| **Validate config** | `terraform validate` | Local validation |
| **Format code** | `terraform fmt -recursive` | Code formatting |
| **Check resources** | `terraform state list` | Local state check |

### 🔗 **Production URLs**

- **Production:** [https://lawnsmartapp.com](https://lawnsmartapp.com)
- **Production (www):** [https://www.lawnsmartapp.com](https://www.lawnsmartapp.com)
- **GitHub Actions:** [View Workflows](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)
- **AWS Console:** [CloudFront Distributions](https://console.aws.amazon.com/cloudfront/v3/home#/distributions)

### 🎯 **State Location**

```bash
# View Terraform state
aws s3 ls s3://lawnsmartapp-terraform-state/
# Expected output:
#   lawnsmartapp-com/terraform.tfstate
```

## 📚 Additional Resources

- **[archived/README.md](archived/README.md)** - Information about deprecated local deployment scripts
- **[GitHub Actions](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)** - Required deployment method
- **[Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)**
- **[AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Terraform Community** for excellent AWS provider
- **AWS Documentation** for architecture best practices  
- **GitHub Actions** for seamless CI/CD integration
- **React Team** for the amazing framework this infrastructure supports

---

**🌱 Built for LawnSmart App - Smart Lawn Care Management**  
*Production Infrastructure deployed with ❤️ using Terraform + AWS + GitHub Actions*