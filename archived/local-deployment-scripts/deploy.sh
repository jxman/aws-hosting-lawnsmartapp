#!/bin/bash

# Unified deployment script for multi-environment Terraform deployments
# Usage: ./deploy.sh <environment> [plan|apply|destroy] [--auto-approve]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALID_ENVIRONMENTS=("dev" "staging" "prod")
VALID_COMMANDS=("plan" "apply" "destroy" "init" "validate")

# Default values
ENVIRONMENT=""
COMMAND="plan"
AUTO_APPROVE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_usage() {
    echo "Usage: $0 <environment> [command] [options]"
    echo ""
    echo "Environments: ${VALID_ENVIRONMENTS[*]}"
    echo "Commands: ${VALID_COMMANDS[*]}"
    echo ""
    echo "Options:"
    echo "  --auto-approve    Skip interactive approval for apply/destroy"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan                    # Plan changes for dev environment"
    echo "  $0 staging apply               # Apply changes to staging"
    echo "  $0 prod apply --auto-approve   # Apply to prod without confirmation"
    echo "  $0 dev destroy                 # Destroy dev infrastructure"
}

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

validate_environment() {
    local env=$1
    for valid_env in "${VALID_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    return 1
}

validate_command() {
    local cmd=$1
    for valid_cmd in "${VALID_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid_cmd" ]]; then
            return 0
        fi
    done
    return 1
}

confirm_action() {
    local env=$1
    local cmd=$2
    
    case $cmd in
        "apply")
            if [[ "$env" == "prod" ]]; then
                warn "You are about to apply changes to PRODUCTION environment!"
                echo "This action can affect live services and users."
            else
                log "Applying changes to $env environment"
            fi
            ;;
        "destroy")
            warn "You are about to DESTROY infrastructure in $env environment!"
            echo "This action is IRREVERSIBLE and will delete all resources."
            ;;
        *)
            return 0
            ;;
    esac
    
    if [[ "$AUTO_APPROVE" == "--auto-approve" ]]; then
        log "Auto-approve enabled, proceeding..."
        return 0
    fi
    
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r response
    case $response in
        [Yy][Ee][Ss])
            return 0
            ;;
        *)
            error "Operation cancelled by user"
            ;;
    esac
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

ENVIRONMENT=$1
shift

if [[ $# -gt 0 ]]; then
    COMMAND=$1
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-approve)
            AUTO_APPROVE="--auto-approve"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate inputs
if ! validate_environment "$ENVIRONMENT"; then
    error "Invalid environment: $ENVIRONMENT. Valid options: ${VALID_ENVIRONMENTS[*]}"
fi

if ! validate_command "$COMMAND"; then
    error "Invalid command: $COMMAND. Valid options: ${VALID_COMMANDS[*]}"
fi

# Check required files
TFVARS_FILE="$SCRIPT_DIR/environments/$ENVIRONMENT/terraform.tfvars"
BACKEND_CONFIG="$SCRIPT_DIR/backend-configs/$ENVIRONMENT.conf"

if [[ ! -f "$TFVARS_FILE" ]]; then
    error "Environment file not found: $TFVARS_FILE"
fi

if [[ ! -f "$BACKEND_CONFIG" ]]; then
    error "Backend config not found: $BACKEND_CONFIG"
fi

# Set environment-specific configurations
case $ENVIRONMENT in
    "prod")
        CONFIRMATION_LEVEL="strict"
        ;;
    "staging")
        CONFIRMATION_LEVEL="medium"
        ;;
    "dev")
        CONFIRMATION_LEVEL="simple"
        ;;
esac

log "Starting Terraform deployment"
log "Environment: $ENVIRONMENT"
log "Command: $COMMAND"
log "Working directory: $SCRIPT_DIR"

# Change to script directory
cd "$SCRIPT_DIR"

# Initialize Terraform with environment-specific backend
if [[ "$COMMAND" == "init" ]] || [[ ! -d ".terraform" ]]; then
    log "Initializing Terraform with $ENVIRONMENT backend configuration..."
    terraform init -backend-config="$BACKEND_CONFIG" -reconfigure
fi

# Execute the requested command
case $COMMAND in
    "init")
        success "Terraform initialization completed"
        ;;
    "validate")
        log "Validating Terraform configuration..."
        terraform validate
        success "Terraform configuration is valid"
        ;;
    "plan")
        log "Planning Terraform changes for $ENVIRONMENT..."
        terraform plan -var-file="$TFVARS_FILE" -out="tfplan-$ENVIRONMENT"
        success "Terraform plan completed"
        ;;
    "apply")
        confirm_action "$ENVIRONMENT" "$COMMAND"
        log "Applying Terraform changes to $ENVIRONMENT..."
        
        # Check if plan file exists
        if [[ -f "tfplan-$ENVIRONMENT" ]]; then
            log "Using existing plan file: tfplan-$ENVIRONMENT"
            if [[ "$AUTO_APPROVE" == "--auto-approve" ]]; then
                terraform apply "tfplan-$ENVIRONMENT"
            else
                terraform apply "tfplan-$ENVIRONMENT"
            fi
        else
            log "No plan file found, creating new plan..."
            if [[ "$AUTO_APPROVE" == "--auto-approve" ]]; then
                terraform apply -var-file="$TFVARS_FILE" -auto-approve
            else
                terraform apply -var-file="$TFVARS_FILE"
            fi
        fi
        success "Terraform apply completed successfully"
        ;;
    "destroy")
        confirm_action "$ENVIRONMENT" "$COMMAND"
        log "Destroying Terraform infrastructure in $ENVIRONMENT..."
        
        if [[ "$AUTO_APPROVE" == "--auto-approve" ]]; then
            terraform destroy -var-file="$TFVARS_FILE" -auto-approve
        else
            terraform destroy -var-file="$TFVARS_FILE"
        fi
        success "Terraform destroy completed"
        ;;
esac

log "Deployment script completed successfully"