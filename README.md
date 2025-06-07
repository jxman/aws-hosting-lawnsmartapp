# 🌱 AWS Hosting Infrastructure for LawnSmart App

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/aws-hosting-lawnsmartapp/terraform.yml?branch=main&style=for-the-badge)

This repository contains Infrastructure as Code (IaC) for deploying a production-ready React application hosting solution on AWS. Specifically designed for the LawnSmart App - a smart lawn care management application.

## 🚀 Live Infrastructure

**Website:** [https://lawnsmartapp.com](https://lawnsmartapp.com) *(DNS propagating)*  
**CloudFront URL:** [https://d1yvxqir7ibuig.cloudfront.net](https://d1yvxqir7ibuig.cloudfront.net)  
**Status:** ✅ **Deployed & Active**

### Current Deployment
- **CloudFront Distribution:** `E1MYY1CD3E7WBQ` (Deployed)
- **SSL Certificate:** `arn:aws:acm:us-east-1:600424110307:certificate/29bff0e9-e81a-4a90-8254-e5ab09253179`
- **Primary S3 Bucket:** `www.lawnsmartapp.com`
- **Failover S3 Bucket:** `www.lawnsmartapp.com-secondary`
- **Coming Soon Page:** 🎉 Active (temporary placeholder)

## 🏗️ Architecture Overview

The infrastructure implements a highly available, scalable architecture optimized for React Single Page Applications:

### Core Components
- **🌐 Multi-Region Setup**: Primary (us-east-1) + Failover (us-west-1)
- **⚡ CloudFront CDN**: Global edge caching with custom domain
- **🔒 SSL/TLS**: Auto-managed certificates with Route53 validation
- **📱 React SPA Support**: Proper routing configuration (404→index.html)
- **🛡️ Security Headers**: CSP, HSTS, X-Frame-Options, etc.
- **📊 Access Logging**: Centralized logging for monitoring
- **🔄 Auto-Replication**: Cross-region S3 replication for resilience

### Architecture Diagram
```
┌─────────────┐    ┌──────────────┐    ┌───────────────┐
│   Route53   │───▶│  CloudFront  │───▶│ Primary S3    │
│ (DNS + SSL) │    │ (Global CDN) │    │ (us-east-1)   │
└─────────────┘    └──────────────┘    └───────────────┘
                          │                      │
                          │                      ▼
                          │              ┌───────────────┐
                          └─────────────▶│ Failover S3   │
                                         │ (us-west-1)   │
                                         └───────────────┘
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

### 2. Environment-Specific Deployment

#### Development Environment (Recommended for testing)
```bash
# Plan changes
./deploy-dev.sh plan

# Deploy infrastructure
./deploy-dev.sh apply
```

#### Production Environment
```bash
# Plan production changes
./deploy-prod.sh plan

# Deploy to production (requires confirmation)
./deploy-prod.sh apply
```

#### Staging Environment
```bash
# Plan staging changes
./deploy-staging.sh plan

# Deploy to staging
./deploy-staging.sh apply
```

### 3. Manual Terraform Operations
```bash
# Initialize with environment-specific backend
terraform init -backend-config=environments/dev/backend.conf

# Plan with environment variables
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 📁 Project Structure

```
📦 aws-hosting-lawnsmartapp/
├── 🏗️ modules/                    # Reusable Terraform modules
│   ├── acm-certificate/           # SSL/TLS certificate management
│   ├── cloudfront/               # CDN + security headers
│   ├── route53/                  # DNS management
│   └── s3-website/               # S3 hosting + replication
├── 🌍 environments/              # Environment-specific configs
│   ├── dev/                      # Development (active)
│   │   ├── backend.conf          # State: lawnsmartapp-terraform-state-dev
│   │   └── terraform.tfvars      # site_name = "lawnsmartapp.com"
│   ├── prod/                     # Production
│   │   ├── backend.conf          # State: lawnsmartapp-terraform-state
│   │   └── terraform.tfvars      # Production variables
│   └── staging/                  # Staging environment
│       ├── backend.conf          # State: lawnsmartapp-terraform-state-staging
│       └── terraform.tfvars      # Staging variables
├── 🚀 .github/workflows/         # CI/CD Pipeline
│   └── terraform.yml             # GitHub Actions deployment
├── 📜 scripts/                   # Helper scripts
│   ├── create-prerequisites.sh   # Creates state infrastructure
│   └── README.md                 # Script documentation
├── 🚢 deploy-*.sh               # Environment deployment scripts
├── 📋 main.tf                    # Main infrastructure
├── 📊 outputs.tf                 # Infrastructure outputs
├── 🔧 variables.tf               # Input variables
├── 📌 versions.tf                # Provider constraints
├── 🗺️ ROADMAP.md                 # Project roadmap
└── 📖 README.md                  # This file
```

## 🔄 GitOps Workflow & State Management

### Deployment Strategy: "Keep It Simple" ⚡
We implement a hybrid approach that balances **development speed** with **production control**:

| Trigger | Environment | Action | Approval Required |
|---------|-------------|---------|------------------|
| **Push to `main`** | Development | ✅ **Automatic Deploy** | ❌ No |
| **Pull Request** | Development | 📋 **Plan Only** | ❌ No |
| **Manual Workflow** | Production | 🎛️ **Manual Deploy** | ✅ **Required** |
| **Local Scripts** | Any | 🔧 **Local Deploy** | ❌ No |

### 🚀 Production Deployment Methods

#### Method 1: GitHub UI (Recommended)
1. **Navigate to** [GitHub Actions](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)
2. **Click** "Terraform Deployment" workflow
3. **Click** "Run workflow" button
4. **Select options:**
   - **Environment:** `prod`
   - **Action:** `plan` (preview) or `apply` (deploy)
5. **Click** "Run workflow"

#### Method 2: GitHub CLI
```bash
# Preview production changes
gh workflow run terraform.yml -f environment=prod -f action=plan

# Deploy to production  
gh workflow run terraform.yml -f environment=prod -f action=apply

# Manual dev deployment (override automatic)
gh workflow run terraform.yml -f environment=dev -f action=apply
```

#### Method 3: Local Deployment (Still Available)
```bash
# Production deployment locally
./deploy-prod.sh plan    # Preview changes
./deploy-prod.sh apply   # Deploy to production

# Development deployment locally  
./deploy-dev.sh plan     # Preview changes
./deploy-dev.sh apply    # Deploy to development
```

### 🏗️ State Management (Perfect Isolation)

| Environment | State Bucket | State Key | Lock Table | Usage |
|-------------|--------------|-----------|------------|-------|
| **Development** | `lawnsmartapp-terraform-state-dev` | `terraform.tfstate` | `lawnsmartapp-terraform-locks-dev` | ✅ **Auto + Manual** |
| **Production** | `lawnsmartapp-terraform-state` | `lawnsmartapp-com/terraform.tfstate` | `terraform-locks` | 🎛️ **Manual Only** |

**🎯 Key Benefits:**
- ✅ **Complete isolation** between dev and prod environments
- ✅ **No state conflicts** or cross-environment contamination  
- ✅ **Local ↔ CI/CD consistency** for each environment
- ✅ **Same infrastructure code** manages both environments

### 🔄 Complete Development Workflow

#### 1. **Feature Development** (Automatic Dev Deployment)
```bash
# Create feature branch
git checkout -b feature/new-infrastructure main

# Make infrastructure changes  
vim modules/cloudfront/main.tf

# Test locally (uses dev state)
./deploy-dev.sh plan
./deploy-dev.sh apply

# Commit and push
git add . && git commit -m "feat: add new infrastructure"
git push origin feature/new-infrastructure
```

#### 2. **Pull Request Validation**
- 🤖 **GitHub Actions automatically runs** `terraform plan`
- 📝 **Plan results posted** as PR comments  
- 👥 **Team reviews** infrastructure changes
- 🛡️ **No deployments** during PR phase

#### 3. **Development Deployment** (Automatic)
```bash
# Merge PR to main
git checkout main && git merge feature/new-infrastructure
git push origin main

# ✅ Triggers automatic development deployment
# 📊 Uses shared dev state file
# 🔄 Infrastructure updated automatically
```

#### 4. **Production Release** (Manual Control)
```bash
# Option A: GitHub UI
# 1. Go to Actions → Terraform Deployment → Run workflow
# 2. Environment: prod, Action: plan (review first)
# 3. Environment: prod, Action: apply (deploy)

# Option B: Command line
gh workflow run terraform.yml -f environment=prod -f action=plan
gh workflow run terraform.yml -f environment=prod -f action=apply

# Option C: Local deployment
./deploy-prod.sh plan && ./deploy-prod.sh apply
```

### 🛡️ Production Safeguards

- 🔒 **Manual approval required** for all production changes
- 📋 **Plan step always runs first** to preview changes  
- 🎯 **Explicit environment selection** prevents accidents
- 📊 **Complete audit trail** in GitHub Actions logs
- 🔐 **OIDC authentication** with no stored AWS secrets
- 🚫 **No automatic production deployments** - ever

## 🛡️ Security Implementation

This infrastructure follows AWS security best practices:

- ✅ **Origin Access Control (OAC)**: S3 buckets only accessible via CloudFront
- ✅ **TLS 1.2+ Encryption**: All traffic encrypted with auto-managed certificates
- ✅ **Security Headers**: Comprehensive CSP, HSTS, X-Frame-Options
- ✅ **IAM Least Privilege**: Minimal permissions for all roles
- ✅ **Access Logging**: Comprehensive audit trail
- ✅ **Public Access Blocked**: S3 buckets completely private
- ✅ **State Encryption**: AES256 encryption for Terraform state

### Implemented Security Headers
```yaml
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

## 📱 React SPA Configuration

The infrastructure is specifically optimized for React applications:

### Custom Error Handling
```terraform
custom_error_response {
  error_caching_min_ttl = 5
  error_code            = 403
  response_code         = 200
  response_page_path    = "/index.html"  # Enables client-side routing
}
```

### Deployment Process
```bash
# Build your React app
npm run build

# Deploy to S3 (replace with your bucket)
aws s3 sync build/ s3://www.lawnsmartapp.com/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1MYY1CD3E7WBQ \
  --paths "/*"
```

## 📊 Infrastructure Outputs

After deployment, these outputs are available:

```bash
terraform output
```

**Current Outputs:**
- **website_url**: `https://lawnsmartapp.com`
- **cloudfront_distribution_id**: `E1MYY1CD3E7WBQ`
- **cloudfront_domain_name**: `d1yvxqir7ibuig.cloudfront.net`
- **certificate_arn**: `arn:aws:acm:us-east-1:600424110307:certificate/29bff0e9-e81a-4a90-8254-e5ab09253179`
- **primary_s3_bucket**: `www.lawnsmartapp.com`
- **failover_s3_bucket**: `www.lawnsmartapp.com-secondary`

## 💰 Cost Optimization

This architecture is designed for cost efficiency:

- **🎯 Intelligent Tiering**: Automatic S3 cost optimization
- **⚡ CloudFront Caching**: Reduced origin requests
- **📊 Lifecycle Policies**: Automated log retention management
- **🔄 Single Distribution**: Origin failover vs duplicate resources
- **💾 Efficient State Storage**: Minimal backend costs

**Estimated Monthly Cost:** ~$5-15 for typical usage

## 🔍 Monitoring & Observability

- **📊 CloudWatch Metrics**: Built-in monitoring for all services
- **📝 Access Logs**: Stored in `lawnsmartapp.com-site-logs` bucket
- **🔄 Health Checks**: Automatic failover monitoring
- **📈 Performance Tracking**: CloudFront analytics
- **🛡️ Security Monitoring**: WAF logs (when enabled)

## 🚦 Troubleshooting & Operations

### Common Issues

**DNS Not Resolving:**
```bash
# Check DNS propagation
dig lawnsmartapp.com
nslookup lawnsmartapp.com 8.8.8.8

# Test CloudFront directly
curl -I https://d1yvxqir7ibuig.cloudfront.net
```

**CloudFront 403 Errors:**
```bash
# Verify S3 bucket policy
aws s3api get-bucket-policy --bucket www.lawnsmartapp.com

# Check Origin Access Control
aws cloudfront get-origin-access-control --id E37JD27FT6OXRT
```

**State Lock Issues:**
```bash
# Check lock status
aws dynamodb scan --table-name lawnsmartapp-terraform-locks-dev
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

**Environment Confusion:**
```bash
# Check which environment you're working with
terraform workspace show

# Verify state backend configuration
cat .terraform/terraform.tfstate | jq '.backend.config'

# List resources in current state
terraform state list
```

### 🔄 Emergency Procedures

**Production Rollback:**
```bash
# Method 1: GitHub UI Rollback
# 1. Go to GitHub Actions → Terraform Deployment → Run workflow
# 2. Use previous commit hash: git checkout <previous-commit>
# 3. Environment: prod, Action: apply

# Method 2: Local Rollback
git checkout <previous-working-commit>
./deploy-prod.sh plan   # Verify rollback plan
./deploy-prod.sh apply  # Execute rollback

# Method 3: State manipulation (advanced)
terraform state rm <resource>  # Remove problematic resource
terraform import <resource> <id>  # Re-import if needed
```

**Split-Brain State Issues:**
```bash
# Check state file consistency
aws s3 cp s3://lawnsmartapp-terraform-state-dev/terraform.tfstate /tmp/dev-state.json
aws s3 cp s3://lawnsmartapp-terraform-state/lawnsmartapp-com/terraform.tfstate /tmp/prod-state.json

# Compare resource counts
cat /tmp/dev-state.json | jq '.resources | length'
cat /tmp/prod-state.json | jq '.resources | length'

# Force refresh if needed
terraform refresh -var-file=environments/dev/terraform.tfvars    # Dev
terraform refresh -var-file=environments/prod/terraform.tfvars   # Prod
```

**Manual State Recovery:**
```bash
# Backup current state
aws s3 cp s3://lawnsmartapp-terraform-state-dev/terraform.tfstate backup-$(date +%Y%m%d).tfstate

# List state versions (if versioning enabled)
aws s3api list-object-versions --bucket lawnsmartapp-terraform-state-dev --prefix terraform.tfstate

# Restore from backup
aws s3 cp backup-20241201.tfstate s3://lawnsmartapp-terraform-state-dev/terraform.tfstate
```

### 🔍 Monitoring & Health Checks

**GitHub Actions Monitoring:**
```bash
# Check workflow status
gh run list --workflow=terraform.yml

# View specific run details  
gh run view <run-id>

# Re-run failed workflow
gh run rerun <run-id>
```

**Infrastructure Health:**
```bash
# Check CloudFront distribution status
aws cloudfront get-distribution --id E1MYY1CD3E7WBQ --query 'Distribution.Status'

# Verify SSL certificate  
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:600424110307:certificate/29bff0e9-e81a-4a90-8254-e5ab09253179

# Test website connectivity
curl -I https://lawnsmartapp.com
curl -I https://www.lawnsmartapp.com
```

**State File Integrity:**
```bash
# Validate state file structure
terraform state pull | jq '.version, .resources | length'

# Check for drift
terraform plan -detailed-exitcode -var-file=environments/dev/terraform.tfvars
# Exit code 0: no changes, 1: error, 2: changes detected
```

## 🧪 Testing

### Infrastructure Testing
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Security scan (if tfsec installed)
tfsec .
```

### Website Testing
```bash
# Test CloudFront
curl -I https://d1yvxqir7ibuig.cloudfront.net

# Test domain (once DNS propagates)
curl -I https://lawnsmartapp.com

# Check security headers
curl -I https://lawnsmartapp.com | grep -E "(Strict-Transport|X-Frame|Content-Security)"
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** your feature branch (`git checkout -b feature/amazing-feature`)
3. **Test** changes in dev environment (`./deploy-dev.sh plan`)
4. **Format** code (`terraform fmt -recursive`)
5. **Commit** changes (`git commit -m 'Add amazing feature'`)
6. **Push** to branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## 📋 Quick Reference

### 🚀 **Common Operations**

| Task | Command | Environment |
|------|---------|-------------|
| **Daily dev work** | `git push origin main` | Development (auto) |
| **Preview prod changes** | `gh workflow run terraform.yml -f environment=prod -f action=plan` | Production |
| **Deploy to prod** | `gh workflow run terraform.yml -f environment=prod -f action=apply` | Production |
| **Local dev deploy** | `./deploy-dev.sh apply` | Development |
| **Local prod deploy** | `./deploy-prod.sh apply` | Production |
| **Check infrastructure** | `terraform output` | Current |
| **Validate config** | `terraform validate && terraform fmt -check` | Any |

### 🔗 **Important URLs**

- **Website:** [https://lawnsmartapp.com](https://lawnsmartapp.com)
- **CloudFront:** [https://d1yvxqir7ibuig.cloudfront.net](https://d1yvxqir7ibuig.cloudfront.net)
- **GitHub Actions:** [View Workflows](https://github.com/jxman/aws-hosting-lawnsmartapp/actions)
- **Manual Deploy:** [Run Workflow](https://github.com/jxman/aws-hosting-lawnsmartapp/actions/workflows/terraform.yml)

### 🎯 **State Locations**

```bash
# Development State
aws s3 ls s3://lawnsmartapp-terraform-state-dev/

# Production State  
aws s3 ls s3://lawnsmartapp-terraform-state/lawnsmartapp-com/
```

## 📚 Additional Resources

- **[ROADMAP.md](ROADMAP.md)** - Future improvements and features
- **[environments/README.md](environments/README.md)** - Environment configuration details  
- **[scripts/README.md](scripts/README.md)** - Deployment script documentation
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
*Deployed with ❤️ using Terraform + AWS + GitHub Actions*