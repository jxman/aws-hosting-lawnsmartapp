#!/bin/bash

# AWS Asset Manager
# Manages AWS Architecture Icons for diagram generation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_CONFIG="$PROJECT_ROOT/.assets-config.json"
DEFAULT_ASSETS_DIR="$HOME/.aws-architecture-icons"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[ASSETS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[ASSETS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[ASSETS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ASSETS]${NC} $1"
}

show_help() {
    cat << EOF
AWS Asset Manager

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    download               Download AWS Architecture Icons
    install PATH           Install assets from downloaded package
    verify [PATH]          Verify asset installation
    list                   List available service icons
    search PATTERN         Search for specific service icons
    map                    Create service-to-icon mapping
    update                 Update existing assets
    cleanup               Clean up temporary files

OPTIONS:
    -d, --dir PATH         Assets directory (default: ~/.aws-architecture-icons)
    -f, --force            Force overwrite existing assets
    -q, --quiet            Quiet mode (minimal output)
    -v, --verbose          Verbose output
    --help                 Show this help

EXAMPLES:
    $(basename "$0") download
    $(basename "$0") install ~/Downloads/Asset-Package_12-01-2023
    $(basename "$0") verify
    $(basename "$0") search lambda
    $(basename "$0") map > service-icons.json

ENVIRONMENT VARIABLES:
    AWS_ASSETS_DIR         Default assets directory

EOF
}

download_assets() {
    log_info "AWS Architecture Icons download information:"
    echo ""
    echo "To download the official AWS Architecture Icons:"
    echo ""
    echo "1. Visit: https://aws.amazon.com/architecture/icons/"
    echo "2. Click 'Download AWS Architecture Icons'"
    echo "3. Extract the downloaded ZIP file"
    echo "4. Run: $(basename "$0") install /path/to/extracted/package"
    echo ""
    log_info "The asset package is typically named: Asset-Package_MM-DD-YYYY.zip"
    
    # Check if we can detect a common download location
    local downloads_dir="$HOME/Downloads"
    if [[ -d "$downloads_dir" ]]; then
        log_info "Checking Downloads directory for asset packages..."
        
        local asset_packages=($(find "$downloads_dir" -name "Asset-Package_*" -type d 2>/dev/null))
        
        if [[ ${#asset_packages[@]} -gt 0 ]]; then
            log_success "Found potential asset packages:"
            for package in "${asset_packages[@]}"; do
                echo "  - $package"
            done
            echo ""
            log_info "To install, run: $(basename "$0") install \"$package\""
        fi
    fi
}

install_assets() {
    local source_path="$1"
    local target_dir="$2"
    local force="$3"
    
    log_info "Installing AWS assets from: $source_path"
    log_info "Target directory: $target_dir"
    
    if [[ ! -d "$source_path" ]]; then
        log_error "Source path does not exist: $source_path"
        exit 1
    fi
    
    # Find the Architecture-Service-Icons directory
    local service_icons_dir=$(find "$source_path" -type d -name "*Architecture-Service-Icons*" | head -1)
    
    if [[ -z "$service_icons_dir" ]]; then
        log_error "Architecture-Service-Icons directory not found in: $source_path"
        log_info "Expected structure: Asset-Package_*/Architecture-Service-Icons_*/"
        exit 1
    fi
    
    log_info "Found service icons at: $service_icons_dir"
    
    # Create target directory
    if [[ -d "$target_dir" && "$force" != "true" ]]; then
        log_error "Target directory already exists: $target_dir"
        log_info "Use --force to overwrite, or choose a different directory"
        exit 1
    fi
    
    mkdir -p "$target_dir"
    
    # Copy service icons
    log_info "Copying service icons..."
    cp -r "$service_icons_dir"/* "$target_dir/"
    
    # Also copy category icons if they exist
    local category_icons_dir=$(find "$source_path" -type d -name "*Category-Icons*" | head -1)
    if [[ -n "$category_icons_dir" ]]; then
        log_info "Found category icons at: $category_icons_dir"
        mkdir -p "$target_dir/Category-Icons"
        cp -r "$category_icons_dir"/* "$target_dir/Category-Icons/"
    fi
    
    # Create asset configuration
    create_assets_config "$target_dir" "$source_path"
    
    # Verify installation
    verify_assets "$target_dir"
    
    log_success "AWS assets installed successfully to: $target_dir"
}

create_assets_config() {
    local assets_dir="$1"
    local source_path="$2"
    
    log_info "Creating assets configuration..."
    
    # Count icons by category
    local icon_count=$(find "$assets_dir" -name "*.svg" | wc -l)
    local categories=($(find "$assets_dir" -type d -name "Arch_*" | xargs -n1 basename | sort))
    
    cat > "$ASSETS_CONFIG" << EOF
{
  "assets_directory": "$assets_dir",
  "source_package": "$source_path",
  "installation_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_icons": $icon_count,
  "categories": [
$(IFS=$'\n'; echo "${categories[*]}" | sed 's/.*/"&"/' | paste -sd ',' -)
  ],
  "preferred_size": "64",
  "format": "svg"
}
EOF
    
    log_success "Assets configuration created: $ASSETS_CONFIG"
}

verify_assets() {
    local assets_dir="$1"
    
    log_info "Verifying asset installation..."
    
    if [[ ! -d "$assets_dir" ]]; then
        log_error "Assets directory not found: $assets_dir"
        return 1
    fi
    
    # Check for service icons
    local service_categories=($(find "$assets_dir" -type d -name "Arch_*" | wc -l))
    log_info "Found $service_categories service categories"
    
    # Check for common services
    local common_services=(
        "Lambda"
        "S3"
        "CloudWatch"
        "SNS"
        "EventBridge"
        "CloudFront"
        "Route53"
        "Certificate-Manager"
    )
    
    local found_services=()
    local missing_services=()
    
    for service in "${common_services[@]}"; do
        if find "$assets_dir" -name "*$service*" -type f | grep -q .; then
            found_services+=("$service")
        else
            missing_services+=("$service")
        fi
    done
    
    log_info "Found icons for services: ${found_services[*]}"
    
    if [[ ${#missing_services[@]} -gt 0 ]]; then
        log_warning "Missing icons for services: ${missing_services[*]}"
    fi
    
    # Check for 64px versions
    local icons_64px=$(find "$assets_dir" -path "*/64/*" -name "*.svg" | wc -l)
    log_info "Found $icons_64px icons in 64px size"
    
    # Total icon count
    local total_icons=$(find "$assets_dir" -name "*.svg" | wc -l)
    log_info "Total SVG icons: $total_icons"
    
    if [[ $total_icons -lt 100 ]]; then
        log_warning "Icon count seems low. Verify installation is complete."
        return 1
    fi
    
    log_success "Asset verification completed successfully"
    return 0
}

list_available_icons() {
    local assets_dir="$1"
    
    if [[ ! -d "$assets_dir" ]]; then
        log_error "Assets directory not found: $assets_dir"
        exit 1
    fi
    
    log_info "Available AWS service icons:"
    echo ""
    
    # List by category
    local categories=($(find "$assets_dir" -type d -name "Arch_*" | sort))
    
    for category in "${categories[@]}"; do
        local category_name=$(basename "$category")
        local icon_count=$(find "$category" -name "*.svg" | wc -l)
        
        echo "📁 $category_name ($icon_count icons)"
        
        # List icons in 64px size if available
        if [[ -d "$category/64" ]]; then
            find "$category/64" -name "*.svg" | head -5 | while read icon; do
                local icon_name=$(basename "$icon" .svg)
                echo "  └── $icon_name"
            done
            
            local total_icons=$(find "$category/64" -name "*.svg" | wc -l)
            if [[ $total_icons -gt 5 ]]; then
                echo "  └── ... and $((total_icons - 5)) more"
            fi
        fi
        echo ""
    done
}

search_icons() {
    local pattern="$1"
    local assets_dir="$2"
    
    if [[ ! -d "$assets_dir" ]]; then
        log_error "Assets directory not found: $assets_dir"
        exit 1
    fi
    
    log_info "Searching for icons matching: $pattern"
    echo ""
    
    # Case-insensitive search
    local results=($(find "$assets_dir" -iname "*$pattern*" -name "*.svg" | sort))
    
    if [[ ${#results[@]} -eq 0 ]]; then
        log_warning "No icons found matching: $pattern"
        return 1
    fi
    
    log_success "Found ${#results[@]} matching icons:"
    
    for result in "${results[@]}"; do
        local relative_path=$(echo "$result" | sed "s|$assets_dir/||")
        local icon_name=$(basename "$result" .svg)
        
        echo "📄 $icon_name"
        echo "   Path: $relative_path"
        
        # Check if 64px version exists
        if echo "$relative_path" | grep -q "/64/"; then
            echo "   Size: 64px ✓"
        else
            # Look for 64px version
            local icon_64px=$(echo "$result" | sed 's|/[0-9]*px/|/64/|')
            if [[ -f "$icon_64px" ]]; then
                echo "   Size: Multiple (64px available) ✓"
            else
                echo "   Size: $(echo "$relative_path" | grep -o '[0-9]*px' || echo 'Unknown')"
            fi
        fi
        echo ""
    done
}

create_service_mapping() {
    local assets_dir="$1"
    
    if [[ ! -d "$assets_dir" ]]; then
        log_error "Assets directory not found: $assets_dir"
        exit 1
    fi
    
    log_info "Creating service-to-icon mapping..."
    
    # Create JSON mapping of common AWS services to their icons
    cat << 'EOF'
{
  "service_mappings": {
EOF
    
    # Common service mappings
    local services=(
        "AWS Lambda:Lambda"
        "Amazon S3:S3:Simple-Storage-Service"
        "Amazon CloudWatch:CloudWatch"
        "Amazon SNS:SNS:Simple-Notification-Service"
        "Amazon EventBridge:EventBridge"
        "Amazon CloudFront:CloudFront"
        "Amazon Route 53:Route53:Route-53"
        "AWS Certificate Manager:Certificate-Manager"
        "Amazon API Gateway:API-Gateway"
        "Amazon DynamoDB:DynamoDB"
        "Amazon RDS:RDS"
        "Amazon EC2:EC2"
        "Amazon VPC:VPC"
        "Amazon ELB:ELB:Elastic-Load-Balancing"
        "AWS IAM:IAM"
        "Amazon ECS:ECS"
        "Amazon EKS:EKS"
        "AWS Fargate:Fargate"
    )
    
    local first=true
    
    for service_def in "${services[@]}"; do
        IFS=':' read -ra service_parts <<< "$service_def"
        local service_name="${service_parts[0]}"
        
        # Try to find the icon file
        local icon_file=""
        for i in "${!service_parts[@]}"; do
            if [[ $i -eq 0 ]]; then continue; fi  # Skip service name
            
            local search_pattern="${service_parts[$i]}"
            icon_file=$(find "$assets_dir" -path "*/64/*" -iname "*$search_pattern*" -name "*.svg" | head -1)
            
            if [[ -n "$icon_file" ]]; then
                break
            fi
        done
        
        if [[ -n "$icon_file" ]]; then
            local relative_path=$(echo "$icon_file" | sed "s|$assets_dir/||")
            
            if [[ "$first" == true ]]; then
                first=false
            else
                echo ","
            fi
            
            echo -n "    \"$service_name\": {
      \"icon_path\": \"$relative_path\",
      \"full_path\": \"$icon_file\",
      \"category\": \"$(dirname "$relative_path" | cut -d'/' -f1)\"
    }"
        fi
    done
    
    echo ""
    echo "  },"
    
    # Add metadata
    echo "  \"metadata\": {"
    echo "    \"assets_directory\": \"$assets_dir\","
    echo "    \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "    \"total_mappings\": $(echo "$services" | wc -w),"
    echo "    \"preferred_size\": \"64px\""
    echo "  }"
    echo "}"
}

update_assets() {
    local assets_dir="$1"
    
    log_info "Checking for asset updates..."
    
    if [[ ! -f "$ASSETS_CONFIG" ]]; then
        log_error "Assets configuration not found. Run install command first."
        exit 1
    fi
    
    local current_dir=$(jq -r '.assets_directory' "$ASSETS_CONFIG")
    local install_date=$(jq -r '.installation_date' "$ASSETS_CONFIG")
    
    log_info "Current installation: $current_dir"
    log_info "Installed on: $install_date"
    
    # Check if assets directory still exists
    if [[ ! -d "$current_dir" ]]; then
        log_error "Current assets directory not found: $current_dir"
        exit 1
    fi
    
    # Re-verify assets
    if verify_assets "$current_dir"; then
        log_success "Assets are up to date and verified"
    else
        log_warning "Asset verification failed. Consider reinstalling."
    fi
}

cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove any temporary mapping files
    find "$PROJECT_ROOT" -name "*.tmp.json" -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name ".asset-cache*" -delete 2>/dev/null || true
    
    log_success "Cleanup completed"
}

main() {
    local command=""
    local assets_dir="${AWS_ASSETS_DIR:-$DEFAULT_ASSETS_DIR}"
    local force=false
    local quiet=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            download|install|verify|list|search|map|update|cleanup)
                command="$1"
                shift
                ;;
            -d|--dir)
                assets_dir="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # This might be a path for install command or pattern for search
                if [[ "$command" == "install" && -z "$install_path" ]]; then
                    install_path="$1"
                elif [[ "$command" == "search" && -z "$search_pattern" ]]; then
                    search_pattern="$1"
                else
                    log_error "Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set verbosity
    if [[ "$quiet" == true ]]; then
        exec 1>/dev/null
    fi
    
    if [[ "$verbose" == true ]]; then
        set -x
    fi
    
    # Default command
    if [[ -z "$command" ]]; then
        show_help
        exit 0
    fi
    
    log_info "AWS Asset Manager - Command: $command"
    
    # Execute the requested command
    case $command in
        download)
            download_assets
            ;;
        install)
            if [[ -z "$install_path" ]]; then
                log_error "Install path required for install command"
                log_info "Usage: $(basename "$0") install /path/to/asset/package"
                exit 1
            fi
            install_assets "$install_path" "$assets_dir" "$force"
            ;;
        verify)
            verify_assets "$assets_dir"
            ;;
        list)
            list_available_icons "$assets_dir"
            ;;
        search)
            if [[ -z "$search_pattern" ]]; then
                log_error "Search pattern required for search command"
                log_info "Usage: $(basename "$0") search lambda"
                exit 1
            fi
            search_icons "$search_pattern" "$assets_dir"
            ;;
        map)
            create_service_mapping "$assets_dir"
            ;;
        update)
            update_assets "$assets_dir"
            ;;
        cleanup)
            cleanup_temp_files
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Asset manager command completed: $command"
}

# Run main function
main "$@"