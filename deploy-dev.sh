#!/bin/bash

# Development Deployment Script for Terraform S3 + CloudFront Infrastructure
# Usage: ./deploy-dev.sh [plan|apply|destroy]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="dev"
BACKEND_CONFIG="environments/${ENVIRONMENT}/backend.conf"
VAR_FILE="environments/${ENVIRONMENT}/terraform.tfvars"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if configuration files exist
    if [ ! -f "$BACKEND_CONFIG" ]; then
        print_error "Backend configuration file not found: $BACKEND_CONFIG"
        exit 1
    fi
    
    if [ ! -f "$VAR_FILE" ]; then
        print_error "Variables file not found: $VAR_FILE"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        print_status "Please run 'aws configure' or set AWS environment variables."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to display current configuration
show_config() {
    print_status "Development Deployment Configuration:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Backend Config: $BACKEND_CONFIG"
    echo "  Variables File: $VAR_FILE"
    echo "  AWS Account: $(aws sts get-caller-identity --query Account --output text)"
    echo "  AWS Region: $(aws configure get region || echo 'Not set')"
    echo ""
}

# Function to initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    
    # Remove existing .terraform directory if it exists (for clean init)
    if [ -d ".terraform" ]; then
        print_warning "Removing existing .terraform directory for clean initialization..."
        rm -rf .terraform
    fi
    
    terraform init -backend-config="$BACKEND_CONFIG"
    
    if [ $? -eq 0 ]; then
        print_success "Terraform initialized successfully!"
    else
        print_error "Terraform initialization failed!"
        exit 1
    fi
}

# Function to validate Terraform configuration
terraform_validate() {
    print_status "Validating Terraform configuration..."
    
    terraform validate
    
    if [ $? -eq 0 ]; then
        print_success "Terraform configuration is valid!"
    else
        print_error "Terraform configuration validation failed!"
        exit 1
    fi
}

# Function to run terraform plan
terraform_plan() {
    print_status "Running Terraform plan..."
    
    terraform plan -var-file="$VAR_FILE" -out=tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Terraform plan completed successfully!"
        echo ""
        print_status "Development environment plan ready for review."
    else
        print_error "Terraform plan failed!"
        exit 1
    fi
}

# Function to run terraform apply
terraform_apply() {
    print_status "Applying Terraform configuration to development..."
    
    # Check if plan file exists
    if [ ! -f "tfplan" ]; then
        print_error "Plan file (tfplan) not found. Please run plan first."
        exit 1
    fi
    
    # Simpler confirmation for dev environment
    echo ""
    print_status "📝 Applying changes to DEVELOPMENT environment"
    read -p "Continue? (y/N): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled by user."
        exit 0
    fi
    
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Development deployment completed successfully!"
        
        # Clean up plan file
        rm -f tfplan
        
        # Show outputs
        echo ""
        print_status "Terraform outputs:"
        terraform output
        
        # Invalidate CloudFront cache if distribution exists
        if terraform output cloudfront_distribution_id &> /dev/null; then
            DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
            if [ -n "$DISTRIBUTION_ID" ]; then
                print_status "Invalidating CloudFront cache..."
                aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*"
                print_success "CloudFront cache invalidation initiated!"
            fi
        fi
        
    else
        print_error "Terraform apply failed!"
        exit 1
    fi
}

# Function to run terraform destroy
terraform_destroy() {
    print_warning "⚠️  You are about to destroy the DEVELOPMENT environment."
    echo ""
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_status "Destruction cancelled by user."
        exit 0
    fi
    
    print_status "Destroying development resources..."
    terraform destroy -var-file="$VAR_FILE" -auto-approve
    
    if [ $? -eq 0 ]; then
        print_success "Development environment destroyed successfully!"
    else
        print_error "Terraform destroy failed!"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  plan     - Run terraform plan (default)"
    echo "  apply    - Run terraform apply (requires plan to be run first)"
    echo "  destroy  - Destroy all resources"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0               # Run plan only"
    echo "  $0 plan          # Run plan only"
    echo "  $0 apply         # Apply planned changes"
    echo "  $0 destroy       # Destroy all resources"
    echo ""
}

# Main execution
main() {
    clear
    echo "======================================"
    echo "🧪 Terraform Development Deployment"
    echo "======================================"
    echo ""
    
    # Parse command line arguments
    COMMAND=${1:-plan}
    
    case $COMMAND in
        "plan")
            check_prerequisites
            show_config
            terraform_init
            terraform_validate
            terraform_plan
            echo ""
            print_status "Next steps:"
            print_status "1. Review the plan output above"
            print_status "2. If everything looks correct, run: $0 apply"
            ;;
        "apply")
            check_prerequisites
            show_config
            terraform_apply
            ;;
        "destroy")
            check_prerequisites
            show_config
            terraform_destroy
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"