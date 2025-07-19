#!/bin/bash

# AWS Architecture Diagram Generator Script
# Automates the process of generating professional AWS architecture diagrams
# using Claude Code and official AWS service icons

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.diagram-config.json"
DIAGRAM_OUTPUT="$PROJECT_ROOT/architecture-diagram.svg"
CLAUDE_PROMPTS_DIR="$SCRIPT_DIR/claude-prompts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
AWS Architecture Diagram Generator

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -c, --config FILE           Path to configuration file (default: .diagram-config.json)
    -o, --output FILE          Output SVG file path (default: architecture-diagram.svg)
    -a, --assets PATH          Path to AWS assets directory
    -e, --environment ENV      Target environment (dev/prod/staging)
    -i, --interactive          Interactive mode for configuration
    -v, --verbose              Verbose output
    -h, --help                 Show this help message

EXAMPLES:
    $(basename "$0")                                    # Use default configuration
    $(basename "$0") -a ~/Downloads/AWS-Assets          # Specify assets path
    $(basename "$0") -e prod -o prod-architecture.svg   # Generate for prod environment
    $(basename "$0") -i                                 # Interactive configuration

EOF
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for Claude Code
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code is not installed or not in PATH"
        log_info "Please install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
    
    # Check for Terraform
    if ! command -v terraform &> /dev/null; then
        log_warning "Terraform not found in PATH. This may affect analysis."
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_warning "Git not found in PATH. Version control features disabled."
    fi
    
    log_success "Dependencies check completed"
}

load_config() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from $config_file"
        
        # Read configuration values, but don't override command line arguments
        if [[ -z "$AWS_ASSETS_PATH" ]]; then
            AWS_ASSETS_PATH=$(jq -r '.aws_assets_path // empty' "$config_file")
        fi
        if [[ -z "$TARGET_ENVIRONMENT" || "$TARGET_ENVIRONMENT" == "dev" ]]; then
            TARGET_ENVIRONMENT=$(jq -r '.default_environment // "dev"' "$config_file")
        fi
        CANVAS_WIDTH=$(jq -r '.canvas.width // 1400' "$config_file")
        CANVAS_HEIGHT=$(jq -r '.canvas.height // 900' "$config_file")
        ICON_SCALE=$(jq -r '.icon_scale // 0.7' "$config_file")
        
        log_success "Configuration loaded successfully"
    else
        log_warning "Configuration file not found: $config_file"
        create_default_config "$config_file"
    fi
}

create_default_config() {
    local config_file="$1"
    
    log_info "Creating default configuration file..."
    
    cat > "$config_file" << EOF
{
  "aws_assets_path": "",
  "default_environment": "dev",
  "canvas": {
    "width": 1400,
    "height": 900
  },
  "icon_scale": 0.7,
  "environments": ["dev", "staging", "prod"],
  "output_format": "svg",
  "include_environment_badges": true,
  "show_data_flows": true,
  "professional_styling": true
}
EOF
    
    log_success "Default configuration created: $config_file"
}

interactive_config() {
    log_info "Starting interactive configuration..."
    
    # AWS Assets Path
    read -p "Enter path to AWS Assets directory: " assets_path
    if [[ -d "$assets_path" ]]; then
        AWS_ASSETS_PATH="$assets_path"
        log_success "Assets path set to: $AWS_ASSETS_PATH"
    else
        log_error "Invalid assets path: $assets_path"
        exit 1
    fi
    
    # Environment
    echo "Available environments:"
    if [[ -d "$PROJECT_ROOT/environments" ]]; then
        ls -1 "$PROJECT_ROOT/environments" | grep -v README
    else
        echo "dev, staging, prod"
    fi
    
    read -p "Enter target environment [dev]: " environment
    TARGET_ENVIRONMENT="${environment:-dev}"
    
    # Update configuration
    update_config_file
    
    log_success "Interactive configuration completed"
}

update_config_file() {
    local config_file="$CONFIG_FILE"
    
    # Create or update configuration
    cat > "$config_file" << EOF
{
  "aws_assets_path": "$AWS_ASSETS_PATH",
  "default_environment": "$TARGET_ENVIRONMENT",
  "canvas": {
    "width": $CANVAS_WIDTH,
    "height": $CANVAS_HEIGHT
  },
  "icon_scale": $ICON_SCALE,
  "environments": ["dev", "staging", "prod"],
  "output_format": "svg",
  "include_environment_badges": true,
  "show_data_flows": true,
  "professional_styling": true
}
EOF
    
    log_success "Configuration file updated: $config_file"
}

verify_terraform_project() {
    log_info "Verifying Terraform project structure..."
    
    # Check for main Terraform files
    local required_files=("main.tf" "variables.tf" "outputs.tf")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_warning "Missing Terraform files: ${missing_files[*]}"
        log_warning "This may affect diagram generation quality"
    fi
    
    # Check for modules directory
    if [[ -d "$PROJECT_ROOT/modules" ]]; then
        local module_count=$(find "$PROJECT_ROOT/modules" -name "*.tf" | wc -l)
        log_info "Found $module_count Terraform module files"
    else
        log_warning "No modules directory found"
    fi
    
    # Check for environments
    if [[ -d "$PROJECT_ROOT/environments" ]]; then
        local env_count=$(ls -1 "$PROJECT_ROOT/environments" | grep -v README | wc -l)
        log_info "Found $env_count environment configurations"
    else
        log_warning "No environments directory found"
    fi
    
    log_success "Terraform project verification completed"
}

verify_aws_assets() {
    local assets_path="$1"
    
    log_info "Verifying AWS assets at: $assets_path"
    
    if [[ ! -d "$assets_path" ]]; then
        log_error "AWS assets directory not found: $assets_path"
        log_info "Please download AWS Architecture Icons from:"
        log_info "https://aws.amazon.com/architecture/icons/"
        exit 1
    fi
    
    # Look for Architecture-Service-Icons directory or Arch_ directories (installed by asset-manager)
    local service_icons_dir=$(find "$assets_path" -type d -name "*Architecture-Service-Icons*" | head -1)
    
    if [[ -z "$service_icons_dir" ]]; then
        # Check if we have Arch_ directories (asset-manager installation)
        local arch_dirs=$(find "$assets_path" -type d -name "Arch_*" | wc -l)
        if [[ $arch_dirs -gt 0 ]]; then
            service_icons_dir="$assets_path"
            log_info "Found $arch_dirs service categories in assets"
        else
            log_error "No AWS service icons found in assets directory"
            log_info "Expected either Architecture-Service-Icons_* subdirectory or Arch_* categories"
            exit 1
        fi
    fi
    
    # Count available icons
    local icon_count=$(find "$service_icons_dir" -name "*.svg" | wc -l)
    log_info "Found $icon_count SVG icons in assets"
    
    # Check for common service icons
    local common_services=("Lambda" "S3" "CloudWatch" "SNS" "EventBridge")
    local found_services=()
    
    for service in "${common_services[@]}"; do
        if find "$service_icons_dir" -name "*$service*" -type f | grep -q .; then
            found_services+=("$service")
        fi
    done
    
    log_info "Found icons for services: ${found_services[*]}"
    log_success "AWS assets verification completed"
    
    # Store the service icons directory path
    SERVICE_ICONS_DIR="$service_icons_dir"
}

create_claude_prompts() {
    log_info "Creating Claude Code prompt files..."
    
    mkdir -p "$CLAUDE_PROMPTS_DIR"
    
    # Phase 1: Project Analysis Prompt
    cat > "$CLAUDE_PROMPTS_DIR/01-analyze-project.md" << 'EOF'
# Project Analysis Prompt

I need to create an AWS architecture diagram for this Terraform project. Can you:

1. **Analyze the Terraform configuration files**
   - Examine main.tf, variables.tf, outputs.tf
   - Review all modules in the modules/ directory
   - Check environment configurations in environments/
   - Identify backend configurations

2. **Identify all AWS services being used**
   - List each AWS resource type
   - Note any data sources
   - Identify provider configurations

3. **Map out the relationships between services**
   - Resource dependencies
   - Data flow patterns
   - Inter-service communication

4. **List the environments configured**
   - Development, staging, production
   - Environment-specific configurations
   - Backend state management

Please provide:
- Complete list of AWS services used
- Service relationship mappings
- Environment configuration summary
- Any special considerations for the architecture

Focus on understanding the complete infrastructure setup and data flows.
EOF

    # Phase 2: Asset Integration Prompt
    cat > "$CLAUDE_PROMPTS_DIR/02-integrate-assets.md" << 'EOF'
# Asset Integration Prompt

I have the official AWS Architecture Icons downloaded to:
'{{AWS_ASSETS_PATH}}'

Can you:

1. **Search through the asset package and find the specific SVG icons**
   - Look for 64px SVG versions of each service we identified
   - Search in Architecture-Service-Icons subdirectories
   - Find icons by service category (Compute, Storage, etc.)

2. **Provide the exact file paths**
   - Complete path to each required icon
   - Verify files exist at those locations
   - Note any alternative names or locations

3. **Extract SVG content for embedding**
   - Read the SVG file contents
   - Prepare for inline embedding in final diagram
   - Ensure proper scaling and positioning

4. **Create service-to-icon mapping**
   - Map each Terraform resource to its icon
   - Handle services with multiple icon options
   - Provide fallback icons for missing services

Please provide a complete mapping of:
- Service Name → Icon File Path → SVG Content

This will be used to generate the professional architecture diagram.
EOF

    # Phase 3: Diagram Generation Prompt
    cat > "$CLAUDE_PROMPTS_DIR/03-generate-diagram.md" << 'EOF'
# Diagram Generation Prompt

Create a professional AWS architecture diagram using the official AWS service icons. Requirements:

## Technical Specifications
- **Canvas Size**: {{CANVAS_WIDTH}}x{{CANVAS_HEIGHT}}
- **Icon Scale**: {{ICON_SCALE}}
- **Format**: SVG with embedded icons
- **Output**: Complete, production-ready diagram

## Visual Requirements
1. **Use official AWS service icons**
   - Embed SVG content directly from asset package
   - Position icons at top-center of service boxes
   - Scale icons consistently ({{ICON_SCALE}} factor)

2. **Professional layout and styling**
   - Follow AWS architecture diagram standards
   - Use official AWS colors from the icons
   - Maintain consistent spacing and alignment
   - Professional typography and labels

3. **Show clear relationships**
   - Data flow arrows between services
   - Proper arrow alignment and labeling
   - Logical service grouping and positioning
   - Clear indication of data direction

4. **Environment indicators**
   - Environment badges ({{TARGET_ENVIRONMENT}})
   - Multi-environment support visualization
   - Clear separation of concerns

## Service Positioning
- Icons centered at translate(centerX, 10) scale({{ICON_SCALE}})
- Service labels at y=95 and y=115 below icons
- Service boxes sized appropriately for content
- Prevent overlapping elements

## Data Flow Representation
- Arrows with proper markers and labels
- Flow direction clearly indicated
- Logical connection points between services
- Professional arrow styling

Generate a complete, production-ready architecture diagram that matches official AWS documentation standards.
EOF

    # Phase 4: Refinement Prompt
    cat > "$CLAUDE_PROMPTS_DIR/04-refine-diagram.md" << 'EOF'
# Diagram Refinement Prompt

Please review and refine the generated diagram to ensure professional quality:

## Quality Checklist

### Visual Quality
- [ ] Icons are properly centered and scaled
- [ ] No overlapping text or visual elements
- [ ] Consistent spacing throughout diagram
- [ ] Professional appearance matching AWS standards

### Technical Accuracy
- [ ] All service relationships are correctly represented
- [ ] Data flow arrows are properly aligned
- [ ] SVG syntax is valid and error-free
- [ ] Icons display correctly in browsers

### Content Accuracy
- [ ] All identified services are included
- [ ] Service labels are accurate and descriptive
- [ ] Environment indicators are correct
- [ ] Data flows match actual architecture

## Specific Fixes
1. **Icon and text positioning**
   - Center icons in service boxes
   - Position text below icons with proper spacing
   - Ensure no overlapping elements

2. **Arrow alignment**
   - Update arrow paths for any repositioned services
   - Ensure arrows connect to service centers
   - Add proper arrow markers and labels

3. **Layout optimization**
   - Adjust spacing for better visual balance
   - Ensure consistent margins and padding
   - Optimize for readability and professionalism

4. **SVG validation**
   - Check for syntax errors
   - Ensure proper viewBox and dimensions
   - Validate embedded SVG content

Please provide the final, polished architecture diagram ready for production use.
EOF

    log_success "Claude Code prompt files created in $CLAUDE_PROMPTS_DIR"
}

execute_claude_workflow() {
    log_info "Executing Claude Code workflow..."
    
    # Check if Claude Code can be run in the current directory
    if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        log_warning "Not in a git repository. Claude Code may have limited functionality."
    fi
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Prepare the comprehensive prompt
    local claude_prompt="$CLAUDE_PROMPTS_DIR/comprehensive-prompt.md"
    
    # Create comprehensive prompt with substitutions
    cat > "$claude_prompt" << EOF
I need to create a professional AWS architecture diagram from my Terraform project. Please follow this workflow:

## Phase 1: Analysis
1. Examine all Terraform files (main.tf, modules/, environments/)
2. Identify AWS services, their relationships, and data flows
3. Detect multi-environment setup (target: $TARGET_ENVIRONMENT)

## Phase 2: Asset Integration  
1. Use the AWS asset package at: '$AWS_ASSETS_PATH'
2. Find the 64px SVG icons for each identified service
3. Extract SVG content for embedding

## Phase 3: Diagram Creation
1. Create a professional SVG diagram (${CANVAS_WIDTH}x${CANVAS_HEIGHT})
2. Use official AWS icons with $ICON_SCALE scale factor
3. Position icons at top-center of service boxes
4. Place service labels below icons
5. Add data flow arrows with labels
6. Include environment badges
7. Use official AWS colors and styling

## Requirements:
- Professional appearance matching AWS standards
- Clear service relationships and data flows
- Proper icon positioning and text alignment  
- No overlapping elements
- Consistent spacing throughout
- Save the final diagram as: $DIAGRAM_OUTPUT

Generate a complete, production-ready architecture diagram.
EOF
    
    log_info "Running Claude Code with comprehensive prompt..."
    
    # Execute Claude Code with the prompt
    if [[ -f "$claude_prompt" ]]; then
        log_info "Executing Claude Code workflow..."
        
        # Check if claude command is available
        if command -v claude >/dev/null 2>&1; then
            log_info "Automatically executing Claude Code..."
            
            # Change to project directory and run claude
            cd "$PROJECT_ROOT" || exit 1
            
            # Execute Claude Code with the prompt
            if claude < "$claude_prompt"; then
                log_success "Claude Code execution completed"
            else
                log_error "Claude Code execution failed"
                log_info "You can manually run: claude < $claude_prompt"
                return 1
            fi
        else
            log_warning "Claude Code CLI not found in PATH"
            log_info "Please install Claude Code CLI or run manually:"
            log_info "claude < $claude_prompt"
            return 1
        fi
    else
        log_error "Failed to create Claude Code prompt file"
        exit 1
    fi
}

validate_output() {
    local output_file="$1"
    
    log_info "Validating output diagram..."
    
    if [[ ! -f "$output_file" ]]; then
        log_error "Output diagram not found: $output_file"
        return 1
    fi
    
    # Check if it's a valid SVG file
    if ! head -5 "$output_file" | grep -q "<svg"; then
        log_error "Output file is not a valid SVG"
        return 1
    fi
    
    # Check file size (should be substantial for a diagram with embedded icons)
    local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
    if [[ $file_size -lt 1000 ]]; then
        log_warning "Output file seems unusually small: ${file_size} bytes"
    fi
    
    log_success "Output diagram validation completed: $output_file"
    log_info "File size: ${file_size} bytes"
    
    return 0
}

cleanup() {
    log_info "Cleaning up temporary files..."
    # Add cleanup logic here if needed
    log_success "Cleanup completed"
}

main() {
    # Default values (will be overridden by config file and command line)
    AWS_ASSETS_PATH=""
    TARGET_ENVIRONMENT=""
    CANVAS_WIDTH=1400
    CANVAS_HEIGHT=900
    ICON_SCALE=0.7
    INTERACTIVE_MODE=false
    VERBOSE=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                DIAGRAM_OUTPUT="$2"
                shift 2
                ;;
            -a|--assets)
                AWS_ASSETS_PATH="$2"
                shift 2
                ;;
            -e|--environment)
                TARGET_ENVIRONMENT="$2"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Enable verbose output if requested
    if [[ "$VERBOSE" == true ]]; then
        set -x
    fi
    
    log_info "Starting AWS Architecture Diagram Generation"
    log_info "Project: $PROJECT_ROOT"
    log_info "Config: $CONFIG_FILE"
    log_info "Output: $DIAGRAM_OUTPUT"
    
    # Execute workflow
    check_dependencies
    load_config "$CONFIG_FILE"
    
    # Override config with command line arguments if provided
    if [[ -n "$AWS_ASSETS_PATH" ]]; then
        log_info "Using AWS assets path from command line: $AWS_ASSETS_PATH"
    fi
    
    if [[ "$INTERACTIVE_MODE" == true ]]; then
        interactive_config
    fi
    
    # Validate inputs
    if [[ -z "$AWS_ASSETS_PATH" ]]; then
        log_error "AWS assets path not configured. Use -a option or run with -i for interactive mode."
        exit 1
    fi
    
    verify_terraform_project
    verify_aws_assets "$AWS_ASSETS_PATH"
    create_claude_prompts
    
    # Execute the main workflow
    if execute_claude_workflow; then
        log_info "Claude Code workflow completed successfully"
        
        # Validate and report results
        if validate_output "$DIAGRAM_OUTPUT"; then
            echo ""
            log_success "Architecture diagram generated and validated!"
            log_info "Output file: $DIAGRAM_OUTPUT"
            log_info "View the diagram in a web browser or SVG viewer"
            
            # Display diagram info
            if command -v file >/dev/null 2>&1; then
                file_info=$(file "$DIAGRAM_OUTPUT")
                log_info "Diagram info: $file_info"
            fi
            
            file_size=$(ls -lh "$DIAGRAM_OUTPUT" 2>/dev/null | awk '{print $5}' || echo "unknown")
            log_info "File size: $file_size"
        else
            log_error "Diagram validation failed"
            exit 1
        fi
    else
        # If automatic execution failed, provide manual instructions
        echo ""
        echo -e "${YELLOW}[FALLBACK]${NC} Automatic execution failed. Please run Claude Code manually:"
        echo -e "${BLUE}cd $(pwd) && claude < scripts/claude-prompts/comprehensive-prompt.md${NC}"
        echo ""
        echo -e "${YELLOW}[ALTERNATIVE]${NC} Copy and paste this prompt into Claude Code:"
        echo -e "${BLUE}cat scripts/claude-prompts/comprehensive-prompt.md${NC}"
        echo ""
        echo -e "${YELLOW}[INFO]${NC} After Claude generates the diagram, it will be saved as: $DIAGRAM_OUTPUT"
        
        # Optional: Wait for manual execution
        echo ""
        echo -e "${YELLOW}[OPTIONAL]${NC} Press Enter after running Claude Code manually to validate the diagram..."
        read -r
        
        if validate_output "$DIAGRAM_OUTPUT"; then
            echo ""
            log_success "Architecture diagram found and validated!"
            log_info "Output file: $DIAGRAM_OUTPUT"
        else
            echo ""
            log_info "No diagram found. Please run Claude Code with the prepared prompt."
            log_info "Prompt file: scripts/claude-prompts/comprehensive-prompt.md"
        fi
    fi
    
    cleanup
    
    log_success "Workflow completed successfully!"
}

# Trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"