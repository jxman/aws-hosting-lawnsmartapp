# Environment Configurations

This directory contains environment-specific configurations for the LawnSmart App AWS hosting infrastructure.

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

Use the unified deployment script for all operations:

```bash
# Development
./deploy.sh dev plan
./deploy.sh dev apply

# Staging
./deploy.sh staging plan
./deploy.sh staging apply

# Production
./deploy.sh prod plan
./deploy.sh prod apply
```

## Environment Differences

| Environment | Domain | State Location | Resource Prefix |
|-------------|--------|----------------|-----------------|
| Development | dev.lawnsmartapp.com | lawnsmartapp-terraform-state/dev/ | dev-lawnsmartapp-* |
| Staging | staging.lawnsmartapp.com | lawnsmartapp-terraform-state/staging/ | staging-lawnsmartapp-* |
| Production | lawnsmartapp.com | lawnsmartapp-terraform-state/prod/ | lawnsmartapp-* |

## Backend Configuration

All environments use unified state management:
- **State Bucket**: `lawnsmartapp-terraform-state` (shared)
- **Lock Table**: `lawnsmartapp-terraform-locks` (shared)
- **Environment Keys**: Separate state files for complete isolation

## Best Practices

1. **Always use the unified deployment script** (`./deploy.sh <env> <action>`)
2. **Test changes in dev first** before promoting to staging/production
3. **Use environment-specific tfvars** for proper resource naming
4. **Complete resource isolation** prevents environment conflicts
5. **Backup state files** are automatically managed via S3 versioning