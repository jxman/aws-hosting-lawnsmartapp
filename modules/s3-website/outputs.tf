output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.www_site.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.www_site.arn
}

output "primary_bucket_regional_domain" {
  description = "Regional domain name of the primary S3 bucket"
  value       = aws_s3_bucket.www_site.bucket_regional_domain_name
}

output "failover_bucket_name" {
  description = "Name of the failover S3 bucket"
  value       = aws_s3_bucket.destination.id
}

output "failover_bucket_arn" {
  description = "ARN of the failover S3 bucket"
  value       = aws_s3_bucket.destination.arn
}

output "failover_bucket_regional_domain" {
  description = "Regional domain name of the failover S3 bucket"
  value       = aws_s3_bucket.destination.bucket_regional_domain_name
}

output "logs_bucket_name" {
  description = "Name of the logs bucket"
  value       = aws_s3_bucket.logs.id
}
