# Environment Configurations

This directory contains environment-specific configurations for the Terraform S3 + CloudFront infrastructure.

## Structure

```
environments/
├── dev/
│   ├── backend.conf      # Development backend configuration
│   └── terraform.tfvars  # Development variables
├── staging/
│   ├── backend.conf      # Staging backend configuration
│   └── terraform.tfvars  # Staging variables
├── prod/
│   ├── backend.conf      # Production backend configuration
│   └── terraform.tfvars  # Production variables
└── README.md            # This file
```

## Usage

### Initialize Terraform for an Environment

```bash
# Production
terraform init -backend-config=environments/prod/backend.conf

# Staging
terraform init -backend-config=environments/staging/backend.conf

# Development
terraform init -backend-config=environments/dev/backend.conf
```

### Plan/Apply for an Environment

```bash
# Production
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars

# Staging
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# Development
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Prerequisites

Before using these configurations, ensure the following resources exist:

### S3 State Buckets
- `synepho-terraform-state-prod`
- `synepho-terraform-state-staging`
- `synepho-terraform-state-dev`

### DynamoDB State Lock Tables
- `terraform-locks-prod`
- `terraform-locks-staging` 
- `terraform-locks-dev`

### Create Prerequisites Script

```bash
#!/bin/bash
# create-prerequisites.sh

ENVIRONMENTS=("prod" "staging" "dev")
REGION="us-east-1"

for env in "${ENVIRONMENTS[@]}"; do
    echo "Creating resources for $env environment..."
    
    # Create S3 bucket for state
    aws s3 mb s3://synepho-terraform-state-$env --region $REGION
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket synepho-terraform-state-$env \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket synepho-terraform-state-$env \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Create DynamoDB table for locking
    aws dynamodb create-table \
        --table-name terraform-locks-$env \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region $REGION
done

echo "All prerequisites created successfully!"
```

## Environment Differences

| Environment | Domain | State Bucket | Lock Table |
|-------------|--------|--------------|------------|
| Production | synepho.com | synepho-terraform-state-prod | terraform-locks-prod |
| Staging | staging.synepho.com | synepho-terraform-state-staging | terraform-locks-staging |
| Development | dev.synepho.com | synepho-terraform-state-dev | terraform-locks-dev |

## Best Practices

1. **Always specify the environment** when running Terraform commands
2. **Never mix environment configurations** - use only one at a time
3. **Test changes in dev/staging** before applying to production
4. **Use separate AWS accounts** for prod vs non-prod (recommended)
5. **Backup state files** regularly across all environments