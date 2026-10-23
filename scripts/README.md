# Scripts

| Script | Purpose |
|---|---|
| `bootstrap-oidc.sh` | Creates or updates the GitHub Actions OIDC provider, IAM role and IAM policy |
| `create-prerequisites.sh` | Creates tagged, versioned, encrypted Terraform state buckets for prod, staging and dev |
| `generate-architecture-diagram.sh` | Generates an SVG architecture diagram with AWS icons using Claude Code |
| `claude-automation.sh` | Claude Code prompt handling for the diagram generator |
| `asset-manager.sh` | Downloads and manages the AWS Architecture Icons |
| `claude-prompts/` | Prompts used by the diagram generator |

None of these deploy infrastructure. Deployments run only in GitHub Actions; see [docs/deployment-guide.md](../docs/deployment-guide.md).

## OIDC Bootstrap

```bash
bash scripts/bootstrap-oidc.sh
```

- Idempotent: creates `token.actions.githubusercontent.com`, `GithubActions-LawnSmartApp-Policy` and `GithubActionsOIDC-LawnSmartApp-Role` if they are missing, otherwise updates their tags and policy document
- The role's trust policy only accepts tokens from `repo:jxman/aws-hosting-lawnsmartapp:*`
- Resources are tagged `ManagedBy = bootstrap-script`
- When you change the role's permissions, update the live policy **and** this script in the same commit

## State Prerequisites

```bash
bash scripts/create-prerequisites.sh
```

Creates `lawnsmartapp-terraform-state` (prod), `lawnsmartapp-terraform-state-staging` and `lawnsmartapp-terraform-state-dev` if they don't exist, with versioning, AES256 encryption, public access blocked, a lifecycle policy and the 10 standard tags. Locking uses S3 lockfiles, so no DynamoDB table is created. It asks for confirmation before creating anything.

## Architecture Diagram Generation

These scripts generate an SVG diagram with official AWS icons. The README's own diagrams are Mermaid and don't depend on them.

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
  -e, --env ENVIRONMENT Target environment (prod) [default: prod]
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
