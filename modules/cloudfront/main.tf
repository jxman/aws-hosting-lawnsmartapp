# Create Origin Access Control (replaces deprecated OAI)
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.environment}-${replace(var.site_name, ".", "-")}-oac"
  description                       = "Origin Access Control for ${var.site_name} (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.environment}-security-headers-${replace(var.site_name, ".", "-")}"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; img-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com; style-src 'self' 'unsafe-inline' data:; font-src 'self' data:; connect-src 'self' https://www.google-analytics.com https://analytics.google.com; frame-src 'self';"
      override                = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled             = true
  price_class         = "PriceClass_200"
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["www.${var.site_name}", var.site_name]
  tags                = var.tags

  # Origin Group with Failover Config
  origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "primary-s3-${var.site_name}"
    }

    member {
      origin_id = "failover-s3-${var.site_name}"
    }
  }

  # Primary Origin with OAC
  origin {
    origin_id                = "primary-s3-${var.site_name}"
    domain_name              = var.primary_bucket_regional_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  # Secondary Origin with OAC
  origin {
    origin_id                = "failover-s3-${var.site_name}"
    domain_name              = var.failover_bucket_regional_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  # Default cache behavior (updated to use origin group)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "groupS3"

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized managed policy
    origin_request_policy_id   = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin managed policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # TLS configuration
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Error responses
  custom_error_response {
    error_caching_min_ttl = 5
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 5
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Optional: WAF association (if WAF module is added)
  web_acl_id = var.web_acl_id != "" ? var.web_acl_id : null
}
