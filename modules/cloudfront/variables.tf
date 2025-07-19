variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "primary_bucket_regional_domain" {
  description = "Regional domain name of the primary S3 bucket"
  type        = string
}

variable "failover_bucket_regional_domain" {
  description = "Regional domain name of the failover S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate"
  type        = string
}

variable "web_acl_id" {
  description = "WAF Web ACL ID (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
