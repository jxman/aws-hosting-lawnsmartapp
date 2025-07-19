variable "base_domain" {
  description = "Base domain name for the project (e.g., lawnsmartapp.com)"
  type        = string
  default     = "lawnsmartapp.com"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*\\.[a-z]{2,}$", var.base_domain))
    error_message = "The base_domain must be a valid domain name."
  }
}

variable "site_name" {
  description = "Domain name for the site - will be computed based on environment"
  type        = string
  default     = ""
}

variable "primary_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover resources"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "jxman/aws-hosting-lawnsmartapp"
}

locals {
  # Environment-specific domain logic
  site_domain = var.environment == "prod" ? var.base_domain : "${var.environment}.${var.base_domain}"

  # Use provided site_name or computed domain
  actual_site_name = var.site_name != "" ? var.site_name : local.site_domain

  # Consistent resource naming pattern
  resource_prefix = "${var.environment}-lawnsmartapp"

  common_tags = {
    Environment = var.environment
    Project     = "lawnsmartapp-website"
    ManagedBy   = "terraform"
    Owner       = "johxan"
    Site        = local.actual_site_name
    BaseProject = var.base_domain
  }
}
