data "aws_route53_zone" "selected" {
  name         = var.base_domain
  private_zone = false
}

# Route53 record for the root domain (no www)
resource "aws_route53_record" "root_site" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.site_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for www subdomain
resource "aws_route53_record" "www_site" {
  zone_id        = data.aws_route53_zone.selected.zone_id
  name           = "www.${var.site_name}"
  type           = "CNAME"
  ttl            = 5
  set_identifier = "live"

  records = [var.site_name]

  weighted_routing_policy {
    weight = 90
  }
}
