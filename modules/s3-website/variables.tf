variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming (e.g., dev-lawnsmartapp)"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover"
  type        = string
  default     = "us-west-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
