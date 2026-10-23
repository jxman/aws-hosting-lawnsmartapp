#!/bin/bash

# Script to create prerequisite infrastructure for Terraform state management
# This creates S3 state buckets for all environments (locking uses S3 lockfiles)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
ENVIRONMENTS=("prod" "staging" "dev")
REGION="us-east-1"
BASE_DOMAIN="lawnsmartapp.com"

# State bucket name for an environment (must match environments/<env>/backend.conf)
state_bucket_name() {
    if [ "$1" = "prod" ]; then
        echo "lawnsmartapp-terraform-state"
    else
        echo "lawnsmartapp-terraform-state-$1"
    fi
}

# Site domain for an environment
site_domain() {
    if [ "$1" = "prod" ]; then
        echo "$BASE_DOMAIN"
    else
        echo "$1.$BASE_DOMAIN"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        print_status "Please run 'aws configure' or set AWS environment variables."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
    
    # Display current AWS context
    echo ""
    print_status "AWS Configuration:"
    echo "  Account ID: $(aws sts get-caller-identity --query Account --output text)"
    echo "  Region: $REGION"
    echo "  User/Role: $(aws sts get-caller-identity --query Arn --output text)"
    echo ""
}

# Function to create S3 bucket for state
create_s3_bucket() {
    local env=$1
    local bucket_name=$(state_bucket_name "$env")
    
    print_status "Creating S3 bucket: $bucket_name"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        print_warning "S3 bucket $bucket_name already exists, skipping creation"
        return 0
    fi
    
    # Create bucket
    aws s3 mb "s3://$bucket_name" --region "$REGION"
    
    # Enable versioning for state recovery
    print_status "Enabling versioning on $bucket_name"
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    
    # Add encryption for security
    print_status "Enabling encryption on $bucket_name"
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }'
    
    # Block public access
    print_status "Blocking public access on $bucket_name"
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Apply standard tags
    print_status "Tagging $bucket_name"
    aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --tagging "TagSet=[{Key=Environment,Value=$env},{Key=ManagedBy,Value=bootstrap-script},{Key=Owner,Value=John Xanthopoulos},{Key=Project,Value=lawnsmartapp},{Key=Service,Value=lawnsmartapp-website},{Key=GithubRepo,Value=github.com/jxman/aws-hosting-lawnsmartapp},{Key=Site,Value=$(site_domain "$env")},{Key=BaseProject,Value=$BASE_DOMAIN},{Key=Name,Value=$bucket_name},{Key=SubService,Value=terraform-state-bucket}]"
    
    # Add lifecycle policy to manage costs
    print_status "Adding lifecycle policy to $bucket_name"
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$bucket_name" \
        --lifecycle-configuration '{
            "Rules": [{
                "ID": "StateFileManagement",
                "Status": "Enabled",
                "Filter": {"Prefix": ""},
                "Transitions": [{
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                }, {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                }],
                "NoncurrentVersionTransitions": [{
                    "NoncurrentDays": 30,
                    "StorageClass": "STANDARD_IA"
                }],
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 365
                }
            }]
        }'
    
    print_success "S3 bucket $bucket_name created and configured successfully!"
}

# Function to verify created resources
verify_resources() {
    local env=$1
    local bucket_name=$(state_bucket_name "$env")
    print_status "Verifying resources for $env environment..."
    
    # Verify S3 bucket
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        print_success "✓ S3 bucket $bucket_name exists and is accessible"
    else
        print_error "✗ S3 bucket $bucket_name verification failed"
        return 1
    fi
    
    return 0
}

# Function to show created resources
show_resources() {
    print_status "Created Resources Summary:"
    echo ""
    
    for env in "${ENVIRONMENTS[@]}"; do
        echo "📁 $env Environment:"
        echo "   S3 Bucket: $(state_bucket_name "$env")"
        echo ""
    done
    
    print_status "Next Steps:"
    echo "1. Run './deploy-prod.sh plan' to test production deployment"
    echo "2. Run './deploy-dev.sh plan' to test development deployment"
    echo "3. Use 'terraform init -backend-config=environments/[env]/backend.conf' for manual operations"
}

# Main execution
main() {
    clear
    echo "================================================"
    echo "🏗️  Terraform State Infrastructure Setup"
    echo "================================================"
    echo ""
    
    check_prerequisites
    
    # Confirmation
    print_warning "This script will create the following resources in AWS:"
    for env in "${ENVIRONMENTS[@]}"; do
        echo "  • S3 bucket: $(state_bucket_name "$env")"
    done
    echo ""
    
    read -p "Do you want to proceed? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled by user."
        exit 0
    fi
    
    echo ""
    print_status "Creating infrastructure for all environments..."
    echo ""
    
    # Create resources for each environment
    for env in "${ENVIRONMENTS[@]}"; do
        echo "🔧 Setting up $env environment:"
        create_s3_bucket "$env"
        verify_resources "$env"
        echo ""
    done
    
    print_success "All prerequisite infrastructure created successfully!"
    echo ""
    show_resources
}

# Run main function
main "$@"