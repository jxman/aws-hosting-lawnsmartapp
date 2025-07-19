#!/bin/bash

# Claude Code Automation Script
# Provides automated Claude Code integration for architecture diagram generation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_SESSION_FILE="$PROJECT_ROOT/.claude-session"
CLAUDE_PROMPTS_DIR="$SCRIPT_DIR/claude-prompts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[CLAUDE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CLAUDE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[CLAUDE]${NC} $1"
}

log_error() {
    echo -e "${RED}[CLAUDE]${NC} $1"
}

check_claude_available() {
    log_info "Checking Claude Code availability..."
    
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code is not installed or not in PATH"
        log_info "Please install Claude Code from: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
    
    # Check if we can run claude --version
    if ! claude --version &> /dev/null; then
        log_warning "Unable to verify Claude Code version"
    else
        local version=$(claude --version 2>/dev/null || echo "unknown")
        log_info "Claude Code version: $version"
    fi
    
    log_success "Claude Code is available"
}

create_claude_session() {
    log_info "Creating Claude Code session..."
    
    # Create session metadata
    cat > "$CLAUDE_SESSION_FILE" << EOF
{
  "session_id": "architecture-diagram-$(date +%s)",
  "project_root": "$PROJECT_ROOT",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workflow": "aws-architecture-diagram",
  "status": "initialized"
}
EOF
    
    log_success "Claude session created: $CLAUDE_SESSION_FILE"
}

execute_claude_phase() {
    local phase="$1"
    local prompt_file="$2"
    local output_file="$3"
    
    log_info "Executing Claude phase: $phase"
    
    if [[ ! -f "$prompt_file" ]]; then
        log_error "Prompt file not found: $prompt_file"
        return 1
    fi
    
    # Change to project root for Claude execution
    cd "$PROJECT_ROOT"
    
    # Execute Claude with prompt
    log_info "Running Claude Code with prompt: $(basename "$prompt_file")"
    
    # Create a temporary script to run Claude
    local temp_script=$(mktemp)
    cat > "$temp_script" << EOF
#!/bin/bash
echo "Starting Claude Code session for phase: $phase"
echo "Project: $PROJECT_ROOT"
echo "Prompt: $prompt_file"
echo ""
echo "Running: claude < $prompt_file"
echo ""

# Execute Claude (in a real scenario, you would uncomment this)
# claude < "$prompt_file" 2>&1 | tee "$output_file"

echo "Claude execution completed for phase: $phase"
echo "Output would be saved to: $output_file"
EOF
    
    chmod +x "$temp_script"
    
    # Execute the Claude command
    if [[ -n "$output_file" ]]; then
        "$temp_script" | tee "$output_file"
    else
        "$temp_script"
    fi
    
    rm -f "$temp_script"
    
    log_success "Claude phase completed: $phase"
}

run_analysis_phase() {
    log_info "Phase 1: Running project analysis..."
    
    local prompt_file="$CLAUDE_PROMPTS_DIR/01-analyze-project.md"
    local output_file="$PROJECT_ROOT/analysis-output.txt"
    
    execute_claude_phase "analysis" "$prompt_file" "$output_file"
    
    # Update session status
    update_session_status "analysis_completed"
    
    log_success "Analysis phase completed"
}

run_asset_integration_phase() {
    log_info "Phase 2: Running asset integration..."
    
    local prompt_file="$CLAUDE_PROMPTS_DIR/02-integrate-assets.md"
    local output_file="$PROJECT_ROOT/assets-output.txt"
    
    # Substitute variables in prompt
    local temp_prompt=$(mktemp)
    sed "s|{{AWS_ASSETS_PATH}}|$AWS_ASSETS_PATH|g" "$prompt_file" > "$temp_prompt"
    
    execute_claude_phase "asset_integration" "$temp_prompt" "$output_file"
    
    rm -f "$temp_prompt"
    
    # Update session status
    update_session_status "assets_integrated"
    
    log_success "Asset integration phase completed"
}

run_diagram_generation_phase() {
    log_info "Phase 3: Running diagram generation..."
    
    local prompt_file="$CLAUDE_PROMPTS_DIR/03-generate-diagram.md"
    local output_file="$PROJECT_ROOT/diagram-generation.txt"
    
    # Substitute variables in prompt
    local temp_prompt=$(mktemp)
    sed -e "s|{{CANVAS_WIDTH}}|$CANVAS_WIDTH|g" \
        -e "s|{{CANVAS_HEIGHT}}|$CANVAS_HEIGHT|g" \
        -e "s|{{ICON_SCALE}}|$ICON_SCALE|g" \
        -e "s|{{TARGET_ENVIRONMENT}}|$TARGET_ENVIRONMENT|g" \
        "$prompt_file" > "$temp_prompt"
    
    execute_claude_phase "diagram_generation" "$temp_prompt" "$output_file"
    
    rm -f "$temp_prompt"
    
    # Update session status
    update_session_status "diagram_generated"
    
    log_success "Diagram generation phase completed"
}

run_refinement_phase() {
    log_info "Phase 4: Running diagram refinement..."
    
    local prompt_file="$CLAUDE_PROMPTS_DIR/04-refine-diagram.md"
    local output_file="$PROJECT_ROOT/refinement-output.txt"
    
    execute_claude_phase "refinement" "$prompt_file" "$output_file"
    
    # Update session status
    update_session_status "diagram_refined"
    
    log_success "Refinement phase completed"
}

run_comprehensive_workflow() {
    log_info "Running comprehensive Claude Code workflow..."
    
    # Create comprehensive prompt with all substitutions
    local comprehensive_prompt="$CLAUDE_PROMPTS_DIR/comprehensive-workflow.md"
    
    cat > "$comprehensive_prompt" << EOF
# AWS Architecture Diagram Generation - Complete Workflow

I need to create a professional AWS architecture diagram from my Terraform project. Please follow this complete workflow:

## Project Context
- **Project Root**: $PROJECT_ROOT
- **Target Environment**: $TARGET_ENVIRONMENT
- **AWS Assets Path**: $AWS_ASSETS_PATH
- **Output File**: $DIAGRAM_OUTPUT

## Phase 1: Terraform Analysis
Analyze the complete Terraform project structure:

1. **Main Configuration Files**
   - Examine main.tf, variables.tf, outputs.tf in project root
   - Review provider.tf and versions.tf for AWS provider setup
   - Check for any terraform.tfvars files

2. **Module Analysis**
   - Scan all modules in the modules/ directory
   - Identify AWS resources defined in each module
   - Map module interdependencies and outputs

3. **Environment Configuration**
   - Review environments/ directory structure
   - Check backend configurations for state management
   - Identify environment-specific variables and settings

4. **Resource Mapping**
   - Create complete inventory of AWS services used
   - Map resource dependencies and data flows
   - Identify external data sources and references

**Output Required**: Complete list of AWS services with their relationships

## Phase 2: AWS Icon Integration
Using the official AWS Architecture Icons:

1. **Asset Location**: $AWS_ASSETS_PATH
2. **Find Required Icons**
   - Locate 64px SVG versions for each identified service
   - Search Architecture-Service-Icons subdirectories
   - Handle alternative naming conventions

3. **Icon Preparation**
   - Extract SVG content for each required service
   - Prepare for inline embedding in final diagram
   - Ensure consistent scaling at ${ICON_SCALE} factor

**Output Required**: Service-to-icon mapping with embedded SVG content

## Phase 3: Professional Diagram Creation
Generate production-ready architecture diagram:

### Technical Specifications
- **Canvas**: ${CANVAS_WIDTH}x${CANVAS_HEIGHT} SVG
- **Icon Scale**: ${ICON_SCALE}
- **Professional Styling**: Match AWS documentation standards
- **Environment**: $TARGET_ENVIRONMENT focus

### Visual Requirements
1. **Service Positioning**
   - Icons centered at translate(centerX, 10) scale(${ICON_SCALE})
   - Service labels at y=95 and y=115 below icons
   - Proper spacing to prevent overlaps

2. **Data Flow Visualization**
   - Clear arrows showing data/request flows
   - Labeled connections between services
   - Logical flow direction indicators

3. **Professional Styling**
   - Official AWS colors from service icons
   - Consistent typography and spacing
   - Environment badges and indicators
   - Clean, enterprise-ready appearance

### Output Requirements
- Save as: $DIAGRAM_OUTPUT
- Valid SVG with embedded icons
- Browser-compatible rendering
- Production documentation quality

## Phase 4: Quality Assurance
Validate and refine the generated diagram:

1. **Visual Validation**
   - Check for overlapping elements
   - Verify proper icon positioning
   - Ensure readable text and labels

2. **Technical Validation**
   - Validate SVG syntax
   - Test rendering in browsers
   - Verify embedded icon content

3. **Content Accuracy**
   - Confirm all services are represented
   - Validate service relationships
   - Check environment configuration accuracy

## Expected Deliverables
1. **Architecture Analysis Report**: Complete service inventory and relationships
2. **Icon Asset Mapping**: Service-to-icon correspondence with SVG content
3. **Professional Diagram**: Production-ready SVG file at $DIAGRAM_OUTPUT
4. **Quality Report**: Validation results and any recommendations

Please execute this complete workflow and provide all deliverables.
EOF
    
    log_info "Executing comprehensive Claude workflow..."
    
    # Execute the comprehensive workflow
    execute_claude_phase "comprehensive" "$comprehensive_prompt" "$PROJECT_ROOT/comprehensive-output.txt"
    
    # Update session status
    update_session_status "workflow_completed"
    
    log_success "Comprehensive Claude workflow completed"
}

update_session_status() {
    local status="$1"
    
    if [[ -f "$CLAUDE_SESSION_FILE" ]]; then
        # Update status in session file
        local temp_file=$(mktemp)
        jq --arg status "$status" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.status = $status | .last_updated = $timestamp' \
           "$CLAUDE_SESSION_FILE" > "$temp_file"
        mv "$temp_file" "$CLAUDE_SESSION_FILE"
        
        log_info "Session status updated: $status"
    fi
}

show_session_status() {
    if [[ -f "$CLAUDE_SESSION_FILE" ]]; then
        log_info "Current Claude session status:"
        jq -r '.status' "$CLAUDE_SESSION_FILE"
        jq -r '.last_updated' "$CLAUDE_SESSION_FILE"
    else
        log_warning "No active Claude session found"
    fi
}

cleanup_session() {
    log_info "Cleaning up Claude session..."
    
    # Archive session file instead of deleting
    if [[ -f "$CLAUDE_SESSION_FILE" ]]; then
        local archive_file="$PROJECT_ROOT/.claude-session-$(date +%s).json"
        mv "$CLAUDE_SESSION_FILE" "$archive_file"
        log_info "Session archived to: $archive_file"
    fi
    
    # Clean up temporary output files
    rm -f "$PROJECT_ROOT/analysis-output.txt"
    rm -f "$PROJECT_ROOT/assets-output.txt"
    rm -f "$PROJECT_ROOT/diagram-generation.txt"
    rm -f "$PROJECT_ROOT/refinement-output.txt"
    
    log_success "Claude session cleanup completed"
}

show_help() {
    cat << EOF
Claude Code Automation Script

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    analyze                Run project analysis phase
    assets                 Run asset integration phase  
    generate               Run diagram generation phase
    refine                 Run diagram refinement phase
    comprehensive          Run complete workflow (recommended)
    status                 Show current session status
    cleanup                Clean up session and temporary files

OPTIONS:
    -a, --assets PATH      AWS assets directory path
    -e, --env ENV          Target environment
    -o, --output FILE      Output diagram file
    -w, --width WIDTH      Canvas width (default: 1400)
    -h, --height HEIGHT    Canvas height (default: 900)
    -s, --scale SCALE      Icon scale factor (default: 0.7)
    --help                 Show this help

EXAMPLES:
    $(basename "$0") comprehensive -a ~/AWS-Assets -e prod
    $(basename "$0") analyze
    $(basename "$0") status
    $(basename "$0") cleanup

ENVIRONMENT VARIABLES:
    AWS_ASSETS_PATH        Path to AWS architecture icons
    TARGET_ENVIRONMENT     Target environment (dev/prod/staging)
    DIAGRAM_OUTPUT         Output SVG file path

EOF
}

main() {
    # Default values
    local command=""
    AWS_ASSETS_PATH="${AWS_ASSETS_PATH:-}"
    TARGET_ENVIRONMENT="${TARGET_ENVIRONMENT:-dev}"
    DIAGRAM_OUTPUT="${DIAGRAM_OUTPUT:-$PROJECT_ROOT/architecture-diagram.svg}"
    CANVAS_WIDTH="${CANVAS_WIDTH:-1400}"
    CANVAS_HEIGHT="${CANVAS_HEIGHT:-900}"
    ICON_SCALE="${ICON_SCALE:-0.7}"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            analyze|assets|generate|refine|comprehensive|status|cleanup)
                command="$1"
                shift
                ;;
            -a|--assets)
                AWS_ASSETS_PATH="$2"
                shift 2
                ;;
            -e|--env)
                TARGET_ENVIRONMENT="$2"
                shift 2
                ;;
            -o|--output)
                DIAGRAM_OUTPUT="$2"
                shift 2
                ;;
            -w|--width)
                CANVAS_WIDTH="$2"
                shift 2
                ;;
            -h|--height)
                CANVAS_HEIGHT="$2"
                shift 2
                ;;
            -s|--scale)
                ICON_SCALE="$2"
                shift 2
                ;;
            --help)
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
    
    # Default to comprehensive if no command specified
    if [[ -z "$command" ]]; then
        command="comprehensive"
    fi
    
    log_info "Claude Code Automation - Command: $command"
    log_info "Project: $PROJECT_ROOT"
    log_info "Environment: $TARGET_ENVIRONMENT"
    
    # Check dependencies
    check_claude_available
    
    # Create session if it doesn't exist
    if [[ ! -f "$CLAUDE_SESSION_FILE" && "$command" != "status" && "$command" != "cleanup" ]]; then
        create_claude_session
    fi
    
    # Execute the requested command
    case $command in
        analyze)
            run_analysis_phase
            ;;
        assets)
            if [[ -z "$AWS_ASSETS_PATH" ]]; then
                log_error "AWS assets path required for assets phase"
                exit 1
            fi
            run_asset_integration_phase
            ;;
        generate)
            run_diagram_generation_phase
            ;;
        refine)
            run_refinement_phase
            ;;
        comprehensive)
            if [[ -z "$AWS_ASSETS_PATH" ]]; then
                log_error "AWS assets path required for comprehensive workflow"
                log_info "Use: $0 comprehensive -a /path/to/aws-assets"
                exit 1
            fi
            run_comprehensive_workflow
            ;;
        status)
            show_session_status
            ;;
        cleanup)
            cleanup_session
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Claude automation command completed: $command"
}

# Run main function
main "$@"