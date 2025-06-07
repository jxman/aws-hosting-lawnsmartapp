output "zone_id" {
  description = "The Route 53 zone ID"
  value       = data.aws_route53_zone.selected.zone_id
}

output "root_fqdn" {
  description = "The fully qualified domain name of the root domain"
  value       = aws_route53_record.root_site.fqdn
}

output "www_fqdn" {
  description = "The fully qualified domain name of the www domain"
  value       = aws_route53_record.www_site.fqdn
}
