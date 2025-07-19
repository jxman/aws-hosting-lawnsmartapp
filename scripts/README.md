# AWS Architecture Diagram Automation Scripts

This directory contains automation scripts for generating professional AWS architecture diagrams from Terraform projects using Claude Code, plus deployment scripts for different environments.

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
│   ├── dev/
│   ├── staging/
│   └── prod/
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
  "environments": ["dev", "test", "staging", "prod"],
  "default_environment": "dev"
}
```

## Deployment Scripts

### Unified Deployment Script (Recommended)
```bash
./deploy.sh <environment> [command] [options]

# Examples:
./deploy.sh dev plan              # Plan development changes
./deploy.sh staging apply         # Deploy to staging
./deploy.sh prod apply            # Deploy to production
```

### Legacy Environment-Specific Scripts
```bash
./deploy-prod.sh [plan|apply|destroy]    # Production deployment
./deploy-dev.sh [plan|apply|destroy]     # Development deployment  
./deploy-staging.sh [plan|apply|destroy] # Staging deployment
```

## Usage Examples

### Plan Changes
```bash
# Plan changes for any environment
./deploy.sh dev plan
./deploy.sh staging plan
./deploy.sh prod plan
```

### Deploy Changes
```bash
# Deploy to any environment
./deploy.sh dev apply
./deploy.sh staging apply
./deploy.sh prod apply
```

### Destroy Environment
```bash
# Destroy any environment (requires confirmation)
./deploy.sh dev destroy
./deploy.sh staging destroy
./deploy.sh prod destroy
```

## Features

### Safety Features
- ✅ **Prerequisites checking** - Validates Terraform, AWS CLI, and credentials
- ✅ **Configuration validation** - Ensures all required files exist
- ✅ **Environment isolation** - Uses environment-specific backend configs
- ✅ **Confirmation prompts** - Prevents accidental deployments
- ✅ **Clean initialization** - Removes stale .terraform directories
- ✅ **Error handling** - Exits on any command failure

### Production Safety
- 🔒 **Strict confirmation** - Requires typing 'yes' to apply
- 🔒 **Destruction protection** - Requires typing 'DELETE' in caps
- 🔒 **Configuration display** - Shows what will be deployed
- 🔒 **AWS account verification** - Displays target account

### Development Convenience
- 🚀 **Faster confirmations** - Simple y/N prompts
- 🚀 **Less strict validation** - Easier to iterate quickly
- 🚀 **Clear environment labeling** - Obvious when in dev mode

## What Each Script Does

### 1. Prerequisites Check
- Verifies Terraform installation
- Verifies AWS CLI installation  
- Checks for backend configuration files
- Checks for variable files
- Validates AWS credentials

### 2. Configuration Display
- Shows target environment
- Shows backend configuration file
- Shows variables file
- Shows AWS account ID
- Shows AWS region

### 3. Terraform Operations
- Clean initialization with environment-specific backend
- Configuration validation
- Plan generation with environment variables
- Safe apply with confirmation
- Automatic CloudFront cache invalidation
- Resource output display

### 4. Post-Deployment
- Shows Terraform outputs
- Invalidates CloudFront cache automatically
- Cleans up temporary plan files

## Error Handling

The scripts will exit with appropriate error messages if:
- Required tools are not installed
- Configuration files are missing
- AWS credentials are invalid
- Terraform commands fail
- User cancels operations

## Security Considerations

### Production Script
- Requires explicit 'yes' confirmation for apply
- Requires typing 'DELETE' in capitals for destroy
- Shows warning messages about production impact
- Displays AWS account for verification

### Development Script  
- Uses simpler y/N confirmations
- Less strict destruction requirements
- Still validates credentials and configuration
- Clear labeling as development environment

## Customization

### Adding New Environments
To add a staging deployment script:

1. Copy `deploy-dev.sh` to `deploy-staging.sh`
2. Change `ENVIRONMENT="dev"` to `ENVIRONMENT="staging"`
3. Update script title and messages
4. Make executable: `chmod +x deploy-staging.sh`

### Modifying Confirmation Requirements
Edit the confirmation prompts in the `terraform_apply()` and `terraform_destroy()` functions to match your security requirements.

## Integration with CI/CD

These scripts can be called from CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Deploy to Production
  run: ./deploy-prod.sh apply
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

However, for production use, the GitHub Actions workflow is recommended as it provides better logging, approval workflows, and integration with PR processes.