# AWS Architecture Diagram Generation - Complete Workflow

I need to create a professional AWS architecture diagram from my Terraform project. Please follow this complete workflow:

## Project Context
- **Project Root**: /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho
- **Target Environment**: prod
- **AWS Assets Path**: /Users/johxan/.aws-architecture-icons
- **Output File**: /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho/architecture-diagram.svg

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

1. **Asset Location**: /Users/johxan/.aws-architecture-icons
2. **Find Required Icons**
   - Locate 64px SVG versions for each identified service
   - Search Architecture-Service-Icons subdirectories
   - Handle alternative naming conventions

3. **Icon Preparation**
   - Extract SVG content for each required service
   - Prepare for inline embedding in final diagram
   - Ensure consistent scaling at 0.7 factor

**Output Required**: Service-to-icon mapping with embedded SVG content

## Phase 3: Professional Diagram Creation
Generate production-ready architecture diagram:

### Technical Specifications
- **Canvas**: 1400x900 SVG
- **Icon Scale**: 0.7
- **Professional Styling**: Match AWS documentation standards
- **Environment**: prod focus

### Visual Requirements
1. **Service Positioning**
   - Icons centered at translate(centerX, 10) scale(0.7)
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
- Save as: /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho/architecture-diagram.svg
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
3. **Professional Diagram**: Production-ready SVG file at /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho/architecture-diagram.svg
4. **Quality Report**: Validation results and any recommendations

Please execute this complete workflow and provide all deliverables.
