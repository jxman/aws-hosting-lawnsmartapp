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
