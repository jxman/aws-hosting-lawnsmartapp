output "website_url" {
  description = "Website URL (domain name)"
  value       = "https://${var.site_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}

output "primary_s3_bucket" {
  description = "Primary S3 bucket name"
  value       = module.s3_website.primary_bucket_name
}

output "failover_s3_bucket" {
  description = "Failover S3 bucket name"
  value       = module.s3_website.failover_bucket_name
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.acm_certificate.certificate_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.cloudfront.distribution_id
  sensitive   = false
}
