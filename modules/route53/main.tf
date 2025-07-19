# Extract root domain for hosted zone lookup
# For dev.lawnsmartapp.com -> lawnsmartapp.com
# For lawnsmartapp.com -> lawnsmartapp.com
locals {
  root_domain = length(split(".", var.site_name)) > 2 ? join(".", slice(split(".", var.site_name), -2, length(split(".", var.site_name)))) : var.site_name
}

data "aws_route53_zone" "selected" {
  name         = local.root_domain
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
