# 🌱 AWS Hosting Infrastructure for LawnSmart App

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/aws-hosting-lawnsmartapp/terraform.yml?branch=main&style=for-the-badge)

This repository contains Infrastructure as Code (IaC) for deploying a production-ready React application hosting solution on AWS with **complete multi-environment isolation**. Specifically designed for the LawnSmart App - a smart lawn care management application.

## 🚀 Live Infrastructure

**Production:** [https://lawnsmartapp.com](https://lawnsmartapp.com) *(Production Environment)*  
**Development:** [https://dev.lawnsmartapp.com](https://dev.lawnsmartapp.com) *(Development Environment)*  
**Staging:** [https://staging.lawnsmartapp.com](https://staging.lawnsmartapp.com) *(Staging Environment)*

### Current Deployments

#### 🟢 Development Environment
- **Domain:** `dev.lawnsmartapp.com`
- **CloudFront Distribution:** `E2PTD8ZT17QPZ7` (Active)
- **SSL Certificate:** `arn:aws:acm:us-east-1:600424110307:certificate/b8fda779-d949-4b2c-9d82-24171477671e`
- **Primary S3 Bucket:** `www.dev.lawnsmartapp.com`
- **Failover S3 Bucket:** `dev-lawnsmartapp-secondary`
- **Status:** ✅ **Deployed & Active**

#### 🔵 Production Environment
- **Domain:** `lawnsmartapp.com`
- **Status:** 🔄 **Ready for Deployment**

#### 🟡 Staging Environment
- **Domain:** `staging.lawnsmartapp.com`
- **Status:** 🔄 **Ready for Deployment**

## 🏗️ Multi-Environment Architecture

The infrastructure implements **complete environment isolation** with consistent patterns across all environments:

### Core Components
- **🌐 Multi-Region Setup**: Primary (us-east-1) + Failover (us-west-1)
- **⚡ CloudFront CDN**: Global edge caching with custom domains
- **🔒 SSL/TLS**: Auto-managed certificates with Route53 validation
- **📱 React SPA Support**: Proper routing configuration (404→index.html)
- **🛡️ Security Headers**: CSP, HSTS, X-Frame-Options, etc.
- **📊 Access Logging**: Centralized logging for monitoring
- **🔄 Auto-Replication**: Cross-region S3 replication for resilience
- **🔐 Environment Isolation**: Complete resource separation

### Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Route53 DNS  │───▶│  CloudFront CDN │───▶│ Primary S3      │
│ (Multi-Domain)  │    │ (Environment    │    │ (us-east-1)     │
│                 │    │  Specific)      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       ▼
        │                       │               ┌─────────────────┐
        │                       └──────────────▶│ Failover S3     │
        │                                       │ (us-west-1)     │
        │                                       │                 │
        ▼                                       └─────────────────┘
┌─────────────────┐
│ Environment     │
│ Isolation:      │
│ • dev.domain    │
│ • staging.domain│
│ • prod.domain   │
└─────────────────┘
```

## 🛠️ Prerequisites

- **Terraform** >= 1.7.0
- **AWS CLI** configured with appropriate credentials
- **Git** for version control
- **Domain name** registered and managed in Route53

## ⚡ Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/jxman/aws-hosting-lawnsmartapp.git
cd aws-hosting-lawnsmartapp
```

### 2. Unified Deployment Script

**🎯 New Unified Approach** - One script handles all environments:

```bash
# Development Environment (Recommended for testing)
./deploy.sh dev plan          # Preview changes
./deploy.sh dev apply         # Deploy to dev environment

# Staging Environment  
./deploy.sh staging plan      # Preview staging changes
./deploy.sh staging apply     # Deploy to staging environment

# Production Environment
./deploy.sh prod plan         # Preview production changes
./deploy.sh prod apply        # Deploy to production (requires confirmation)

# Additional Commands
./deploy.sh dev init          # Initialize environment backend
./deploy.sh dev validate      # Validate configuration
./deploy.sh dev destroy       # Destroy environment (with confirmation)
```

### 3. Environment-Specific Operations
```bash
# Check what environment you're working with
./deploy.sh dev plan | head -10

# Apply with auto-approval (skip confirmation)
./deploy.sh dev apply --auto-approve

# Initialize specific environment backend
./deploy.sh staging init
```

## 📁 Project Structure (Redesigned)

```
📦 aws-hosting-lawnsmartapp/
├── 🏗️ modules/                    # Reusable Terraform modules
│   ├── acm-certificate/           # SSL/TLS certificate management
│   ├── cloudfront/               # CDN + security headers (env-aware)
│   ├── github-oidc/              # OIDC authentication for GitHub Actions
│   ├── route53/                  # DNS management (multi-domain)
│   └── s3-website/               # S3 hosting + replication (env-prefixed)
├── 🌍 environments/              # Environment-specific configs
│   ├── dev/terraform.tfvars      # base_domain = "lawnsmartapp.com", env = "dev"
│   ├── prod/terraform.tfvars     # base_domain = "lawnsmartapp.com", env = "prod"  
│   └── staging/terraform.tfvars  # base_domain = "lawnsmartapp.com", env = "staging"
├── 🗂️ backend-configs/           # Environment-specific state backends
│   ├── dev.conf                  # State: lawnsmartapp-terraform-state/dev/
│   ├── staging.conf              # State: lawnsmartapp-terraform-state/staging/
│   └── prod.conf                 # State: lawnsmartapp-terraform-state/prod/
├── 🚀 .github/workflows/         # CI/CD Pipeline
│   └── terraform.yml             # GitHub Actions (multi-env support)
├── 🚢 deploy.sh                  # 🆕 Unified deployment script
├── 📋 main.tf                    # Main infrastructure (env-aware)
├── 📊 outputs.tf                 # Infrastructure outputs
├── 🔧 variables.tf               # Input variables (with env logic)
├── 📌 versions.tf                # Provider constraints
├── 📋 DEPLOYMENT.md              # 🆕 Multi-environment deployment guide
└── 📖 README.md                  # This file
```

## 🔄 Multi-Environment GitOps Workflow

### Environment Strategy: **Complete Isolation** 🎯

| Environment | Domain | Auto-Deploy | Manual Deploy | State Isolation |
|-------------|--------|-------------|---------------|-----------------|
| **Development** | `dev.lawnsmartapp.com` | ✅ **Push to main** | ✅ Available | 🔐 **dev/** |
| **Staging** | `staging.lawnsmartapp.com` | ❌ Manual only | ✅ Available | 🔐 **staging/** |
| **Production** | `lawnsmartapp.com` | ❌ Manual only | ✅ **Confirmation Required** | 🔐 **prod/** |

### 🚀 Deployment Methods

#### Method 1: GitHub Actions (Recommended)
```bash
# Preview changes in any environment
gh workflow run terraform.yml -f environment=dev -f action=plan
gh workflow run terraform.yml -f environment=staging -f action=plan  
gh workflow run terraform.yml -f environment=prod -f action=plan

# Deploy to specific environment
gh workflow run terraform.yml -f environment=dev -f action=apply
gh workflow run terraform.yml -f environment=staging -f action=apply
gh workflow run terraform.yml -f environment=prod -f action=apply
```

#### Method 2: Local Deployment (Full Control)
```bash
# Work with any environment locally
./deploy.sh dev plan && ./deploy.sh dev apply
./deploy.sh staging plan && ./deploy.sh staging apply  
./deploy.sh prod plan && ./deploy.sh prod apply
```

#### Method 3: GitHub UI
1. **Navigate to** [GitHub Actions](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)
2. **Click** "Terraform Deployment" workflow → "Run workflow"
3. **Select Environment:** `dev`, `staging`, or `prod`
4. **Select Action:** `plan` (preview) or `apply` (deploy)

### 🏗️ State Management (Perfect Isolation)

**🎯 Unified State Bucket with Environment Keys:**

| Environment | State Location | Lock Table | Resource Prefix |
|-------------|----------------|------------|-----------------|
| **Development** | `lawnsmartapp-terraform-state/dev/terraform.tfstate` | `lawnsmartapp-terraform-locks` | `dev-lawnsmartapp-*` |
| **Staging** | `lawnsmartapp-terraform-state/staging/terraform.tfstate` | `lawnsmartapp-terraform-locks` | `staging-lawnsmartapp-*` |
| **Production** | `lawnsmartapp-terraform-state/prod/terraform.tfstate` | `lawnsmartapp-terraform-locks` | `lawnsmartapp-*` (clean) |

**🎯 Key Benefits:**
- ✅ **Complete resource isolation** - no naming conflicts
- ✅ **Shared state infrastructure** - simplified management
- ✅ **Environment-specific prefixes** - clear resource ownership
- ✅ **Unified deployment patterns** - same commands for all environments

### 🔄 Development Workflow

#### 1. **Feature Development** (Auto-Deploy to Dev)
```bash
# Make infrastructure changes
vim modules/cloudfront/main.tf

# Test locally in dev
./deploy.sh dev plan
./deploy.sh dev apply

# Commit and push (triggers auto-deploy to dev)
git add . && git commit -m "feat: add new infrastructure"
git push origin main
# ✅ Automatically deploys to dev.lawnsmartapp.com
```

#### 2. **Staging Validation** (Manual)
```bash
# Promote to staging environment  
./deploy.sh staging plan      # Review changes
./deploy.sh staging apply     # Deploy to staging.lawnsmartapp.com

# Or via GitHub Actions
gh workflow run terraform.yml -f environment=staging -f action=apply
```

#### 3. **Production Release** (Manual + Confirmation)
```bash
# Production deployment (requires confirmation)
./deploy.sh prod plan         # Review production changes
./deploy.sh prod apply        # Deploy to lawnsmartapp.com (asks for confirmation)

# Or via GitHub Actions
gh workflow run terraform.yml -f environment=prod -f action=apply
```

## 🛡️ Environment Isolation & Security

### Resource Naming Patterns
Each environment uses consistent, isolated naming:

#### Development Resources
- **S3 Buckets:** `dev-lawnsmartapp-site-logs`, `www.dev.lawnsmartapp.com`, `dev-lawnsmartapp-secondary`
- **IAM Roles:** `dev-lawnsmartapp-replication-role`
- **CloudFront:** `dev-dev-lawnsmartapp-com-oac`
- **Domain:** `dev.lawnsmartapp.com`

#### Staging Resources  
- **S3 Buckets:** `staging-lawnsmartapp-site-logs`, `www.staging.lawnsmartapp.com`, `staging-lawnsmartapp-secondary`
- **IAM Roles:** `staging-lawnsmartapp-replication-role`
- **CloudFront:** `staging-staging-lawnsmartapp-com-oac`
- **Domain:** `staging.lawnsmartapp.com`

#### Production Resources
- **S3 Buckets:** `lawnsmartapp-site-logs`, `www.lawnsmartapp.com`, `lawnsmartapp-secondary`  
- **IAM Roles:** `prod-lawnsmartapp-replication-role`
- **CloudFront:** `prod-lawnsmartapp-com-oac`
- **Domain:** `lawnsmartapp.com`

### Security Implementation
- ✅ **Project-Specific IAM Role**: `GithubActionsOIDC-LawnSmartApp-Role`
- ✅ **Environment-Specific Resources**: Complete isolation prevents conflicts
- ✅ **OIDC Authentication**: No stored AWS credentials in GitHub
- ✅ **Least Privilege Permissions**: IAM policies scoped to project resources
- ✅ **State Encryption**: AES256 encryption for all Terraform state
- ✅ **Origin Access Control**: S3 buckets only accessible via CloudFront

## 📱 React SPA Configuration

Optimized for React applications across all environments:

### Custom Error Handling
```terraform
custom_error_response {
  error_caching_min_ttl = 5
  error_code            = 403
  response_code         = 200
  response_page_path    = "/index.html"  # Enables client-side routing
}
```

### Environment-Specific Deployment
```bash
# Build your React app
npm run build

# Deploy to specific environment
aws s3 sync build/ s3://www.dev.lawnsmartapp.com/ --delete          # Dev
aws s3 sync build/ s3://www.staging.lawnsmartapp.com/ --delete      # Staging  
aws s3 sync build/ s3://www.lawnsmartapp.com/ --delete              # Production

# Invalidate CloudFront cache (get distribution ID from terraform output)
aws cloudfront create-invalidation --distribution-id E2PTD8ZT17QPZ7 --paths "/*"
```

## 📊 Infrastructure Outputs

View outputs for any environment:

```bash
# Development outputs
./deploy.sh dev plan | grep -A 10 "Changes to Outputs"
terraform output  # (when in dev context)

# Staging outputs  
./deploy.sh staging plan | grep -A 10 "Changes to Outputs"

# Production outputs
./deploy.sh prod plan | grep -A 10 "Changes to Outputs"
```

**Sample Dev Environment Outputs:**
- **website_url**: `https://dev.lawnsmartapp.com`
- **cloudfront_distribution_id**: `E2PTD8ZT17QPZ7`
- **cloudfront_domain_name**: `d3eg6tuz3zkuh9.cloudfront.net`
- **certificate_arn**: `arn:aws:acm:us-east-1:600424110307:certificate/b8fda779-d949-4b2c-9d82-24171477671e`
- **primary_s3_bucket**: `www.dev.lawnsmartapp.com`
- **failover_s3_bucket**: `dev-lawnsmartapp-secondary`

## 🔍 Troubleshooting & Operations

### Environment-Specific Debugging

**Check Environment State:**
```bash
# Verify which environment you're working with
./deploy.sh dev init    # Confirms dev backend
./deploy.sh staging init    # Confirms staging backend
./deploy.sh prod init   # Confirms production backend

# List resources in specific environment  
terraform init -backend-config=backend-configs/dev.conf
terraform state list

terraform init -backend-config=backend-configs/staging.conf  
terraform state list

terraform init -backend-config=backend-configs/prod.conf
terraform state list
```

**DNS Resolution Testing:**
```bash
# Test all environments
dig dev.lawnsmartapp.com      # Development
dig staging.lawnsmartapp.com  # Staging
dig lawnsmartapp.com          # Production

# Test CloudFront endpoints
curl -I https://dev.lawnsmartapp.com
curl -I https://staging.lawnsmartapp.com  
curl -I https://lawnsmartapp.com
```

**State Lock Issues:**
```bash
# Check lock status for specific environment
aws dynamodb scan --table-name lawnsmartapp-terraform-locks \
  --filter-expression "contains(LockID, :env)" \
  --expression-attribute-values '{":env":{"S":"dev"}}'

# Force unlock specific environment (use with caution)
terraform force-unlock <LOCK_ID> -backend-config=backend-configs/dev.conf
```

### Emergency Procedures

**Environment Rollback:**
```bash
# Method 1: Git rollback + redeploy
git checkout <previous-working-commit>
./deploy.sh <environment> plan    # Review rollback plan
./deploy.sh <environment> apply   # Execute rollback

# Method 2: GitHub Actions rollback
# Use the GitHub UI to re-run a previous successful workflow
```

**Environment Isolation Verification:**
```bash
# Ensure no resource conflicts between environments
aws s3 ls | grep lawnsmartapp                    # Should show env-prefixed buckets
aws iam list-roles | grep lawnsmartapp          # Should show env-prefixed roles  
aws cloudfront list-distributions | grep lawnsmartapp  # Should show env-specific distributions
```

## 🧪 Testing & Validation

### Infrastructure Testing
```bash
# Validate configuration for all environments
./deploy.sh dev validate
./deploy.sh staging validate  
./deploy.sh prod validate

# Check formatting
terraform fmt -check -recursive

# Test deployment without applying
./deploy.sh dev plan
./deploy.sh staging plan
./deploy.sh prod plan
```

### Environment Connectivity Testing
```bash
# Test all environments
curl -I https://dev.lawnsmartapp.com
curl -I https://staging.lawnsmartapp.com
curl -I https://lawnsmartapp.com

# Check security headers across environments
for env in dev staging www; do
  echo "=== ${env}.lawnsmartapp.com ==="
  curl -I https://${env}.lawnsmartapp.com | grep -E "(Strict-Transport|X-Frame|Content-Security)"
done
```

## 📋 Quick Reference

### 🚀 **Common Operations**

| Task | Command | Environment |
|------|---------|-------------|
| **Deploy to dev** | `git push origin main` | Development (auto) |
| **Deploy to staging** | `./deploy.sh staging apply` | Staging |
| **Deploy to production** | `./deploy.sh prod apply` | Production |
| **Preview changes** | `./deploy.sh <env> plan` | Any |
| **Initialize environment** | `./deploy.sh <env> init` | Any |
| **Validate config** | `./deploy.sh <env> validate` | Any |
| **Format code** | `terraform fmt -recursive` | All |
| **Check environment** | `terraform state list` | Current |

### 🔗 **Environment URLs**

- **Development:** [https://dev.lawnsmartapp.com](https://dev.lawnsmartapp.com)
- **Staging:** [https://staging.lawnsmartapp.com](https://staging.lawnsmartapp.com)  
- **Production:** [https://lawnsmartapp.com](https://lawnsmartapp.com)
- **GitHub Actions:** [View Workflows](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)

### 🎯 **State Locations**

```bash
# View all environment states
aws s3 ls s3://lawnsmartapp-terraform-state/
# Expected output:
#   dev/
#   staging/  
#   prod/
```

## 📚 Additional Resources

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive multi-environment deployment guide
- **[deploy.sh](deploy.sh)** - Unified deployment script documentation  
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
*Multi-Environment Infrastructure deployed with ❤️ using Terraform + AWS + GitHub Actions*