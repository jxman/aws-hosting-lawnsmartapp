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
