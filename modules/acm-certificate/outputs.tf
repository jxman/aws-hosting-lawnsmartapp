output "certificate_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_validation_complete" {
  description = "Indicates certificate validation is complete"
  value       = aws_acm_certificate.cert.arn
}
