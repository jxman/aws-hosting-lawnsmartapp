resource "aws_acm_certificate" "cert" {
  domain_name               = var.site_name
  subject_alternative_names = ["www.${var.site_name}"]
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Extract root domain for hosted zone lookup
# For dev.lawnsmartapp.com -> lawnsmartapp.com
# For lawnsmartapp.com -> lawnsmartapp.com
locals {
  root_domain = length(split(".", var.site_name)) > 2 ? join(".", slice(split(".", var.site_name), length(split(".", var.site_name)) - 2, length(split(".", var.site_name)))) : var.site_name
}

data "aws_route53_zone" "cert" {
  name         = local.root_domain
  private_zone = false
}

resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.cert.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
  timeouts {
    create = "60m"
  }
}
