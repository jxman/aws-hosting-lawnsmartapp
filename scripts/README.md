# AWS Architecture Diagram Automation Scripts

**🔐 Security Policy: Local deployment scripts have been deprecated. All infrastructure deployments now use GitHub Actions with OIDC authentication.**

This directory contains automation scripts for generating professional AWS architecture diagrams from Terraform projects using Claude Code.

## Architecture Diagram Generation

### Prerequisites

Before using the diagram generation scripts on a new project, ensure you have:

1. **Claude Code installed** - Follow the [installation guide](https://docs.anthropic.com/en/docs/claude-code)
2. **Terraform project** - With properly structured `.tf` files and modules
3. **AWS Architecture Icons** - Downloaded from AWS official source

### Setup for New Projects

Follow these steps to set up diagram generation for any new Terraform project:

#### Step 1: Copy Scripts to Your Project

```bash
# Copy all scripts to your project's scripts directory
cp -r /path/to/this/project/scripts /path/to/your/new/project/

# Make scripts executable
chmod +x /path/to/your/new/project/scripts/*.sh
```

#### Step 2: Install AWS Architecture Icons (One-time setup)

```bash
# Navigate to your new project
cd /path/to/your/new/project

# Download AWS Architecture Icons
./scripts/asset-manager.sh download

# Install assets (replace with your downloaded package path)
./scripts/asset-manager.sh install ~/Downloads/Asset-Package_12-01-2023
```

#### Step 3: Configure for Your Project

```bash
# Copy and customize the configuration file
cp .diagram-config.json /path/to/your/new/project/

# Edit the configuration file to match your project structure
# Update service mappings, environment names, and layout preferences
```

#### Step 4: Generate Your First Diagram

```bash
# Navigate to your project root
cd /path/to/your/new/project

# Generate architecture diagram for production environment
./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons -e prod

# Or use default environment (dev)
./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons
```

### Quick Start (Existing Setup)

If you've already set up the icons and scripts:

```bash
# Generate architecture diagram
./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons -e prod
```

### Diagram Automation Scripts

1. **Main Workflow Script** (`generate-architecture-diagram.sh`) - Orchestrates the complete diagram generation process
2. **Claude Code Integration** (`claude-automation.sh`) - Handles Claude Code interactions and prompt management  
3. **Asset Management** (`asset-manager.sh`) - Manages AWS Architecture Icons and service mappings

### Script Usage Options

#### Main Workflow Script
```bash
./scripts/generate-architecture-diagram.sh [OPTIONS]

Options:
  -a, --assets PATH     Path to AWS Architecture Icons directory (required)
  -e, --env ENVIRONMENT Target environment (dev/staging/prod) [default: dev]
  -c, --config FILE     Custom configuration file [default: .diagram-config.json]
  -o, --output FILE     Output SVG file path [default: architecture-diagram.svg]
  -h, --help            Show help message

Examples:
  # Basic usage
  ./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons
  
  # Production environment
  ./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons -e prod
  
  # Custom output file
  ./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons -o my-diagram.svg
  
  # Custom configuration
  ./scripts/generate-architecture-diagram.sh -a ~/.aws-architecture-icons -c custom-config.json
```

#### Asset Manager Script
```bash
./scripts/asset-manager.sh [COMMAND] [OPTIONS]

Commands:
  download              Download AWS Architecture Icons package
  install PATH          Install icons from downloaded package
  verify                Verify installation and show available icons
  search TERM           Search for icons containing TERM
  update                Update to latest icon package
  
Examples:
  # Download latest icons
  ./scripts/asset-manager.sh download
  
  # Install from downloaded package
  ./scripts/asset-manager.sh install ~/Downloads/Asset-Package_12-01-2023
  
  # Verify installation
  ./scripts/asset-manager.sh verify
  
  # Search for S3 icons
  ./scripts/asset-manager.sh search S3
```

### Project Structure Requirements

Your Terraform project should have this structure for optimal results:

```
your-project/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── provider.tf               # Provider configuration
├── modules/                  # Custom modules
│   ├── s3-website/
│   ├── cloudfront/
│   └── route53/
├── environments/             # Environment-specific configs
│   └── prod/                 # Production configuration only
├── scripts/                  # Automation scripts (copied)
│   ├── generate-architecture-diagram.sh
│   ├── claude-automation.sh
│   └── asset-manager.sh
└── .diagram-config.json      # Diagram configuration
```

### Configuration Customization

Edit `.diagram-config.json` to customize:

1. **Service Mappings** - Map your Terraform resources to AWS service names
2. **Layout Templates** - Define positioning for different architecture patterns
3. **Visual Settings** - Colors, fonts, sizes, and spacing
4. **Environment Settings** - Supported environments and their configurations

Example customization:
```json
{
  "service_mappings": {
    "aws_lambda_function": {
      "display_name": "AWS Lambda",
      "category": "Compute",
      "icon_search": ["Lambda"],
      "description": "Serverless functions"
    }
  },
  "environments": ["prod"],
  "default_environment": "prod"
}
```

## Deprecated: Local Deployment Scripts

**⚠️ DEPRECATED: Local deployment scripts have been archived and are no longer supported.**

### Current Deployment Method (GitHub Actions)

All infrastructure deployments now use GitHub Actions with OIDC authentication:

```bash
# Deploy infrastructure changes
gh workflow run "Terraform Deployment" --ref main

# Monitor deployment status
gh run list --limit 5
gh run view [RUN_ID] --web
```

### Why GitHub Actions?

- ✅ **OIDC Authentication**: Secure AWS access without stored credentials
- ✅ **Audit Trail**: Complete deployment history and logging
- ✅ **Consistency**: Standardized deployment environment
- ✅ **Team Visibility**: All deployments tracked and visible
- ✅ **Best Practices**: Infrastructure deployed through CI/CD

### Archived Scripts Location

Previous local deployment scripts have been moved to:
- **Location**: `../archived/local-deployment-scripts/`
- **Status**: DEPRECATED - Use GitHub Actions instead
- **Documentation**: See `../archived/README.md`

## Local Development Commands

For local development and testing (read-only operations only):

```bash
# Format and validate Terraform
terraform fmt -recursive
terraform validate

# Preview changes (requires AWS credentials)
terraform plan

# Check syntax and formatting
terraform fmt -check -recursive
```

## Security Considerations

### GitHub Actions Security (Current)
- 🔐 **OIDC Authentication**: No stored AWS credentials
- 🔐 **Repository Isolation**: IAM trust policy restricted to specific repository
- 🔐 **Least Privilege**: IAM permissions scoped to required resources
- 🔐 **Audit Trail**: All deployments logged in GitHub Actions and CloudTrail

### Deprecated Local Scripts (Archived)
- ⚠️ **Security Risk**: Required local AWS credentials
- ⚠️ **No Audit Trail**: Local deployments not centrally logged
- ⚠️ **Inconsistent Environment**: Different deployment environments across team
- ⚠️ **No Team Visibility**: Deployments not visible to team members

## Integration with GitHub Actions

The current GitHub Actions workflow provides:

```yaml
# Example GitHub Actions usage (automated)
name: Terraform Deployment
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/GithubActionsOIDC-LawnSmartApp-Role
          aws-region: us-east-1
      - name: Deploy Infrastructure
        run: |
          terraform init
          terraform plan
          terraform apply -auto-approve
```

For more details, see the [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md).