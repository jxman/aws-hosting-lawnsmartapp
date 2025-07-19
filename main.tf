# Data source to get current AWS account info
data "aws_caller_identity" "current" {}

# GitHub OIDC Module for secure CI/CD
module "github_oidc" {
  source = "./modules/github-oidc"

  project_name      = "LawnSmartApp"
  github_repository = var.github_repository
  aws_account_id    = data.aws_caller_identity.current.account_id
  tags              = local.common_tags
}

# ACM Certificate Module
module "acm_certificate" {
  source = "./modules/acm-certificate"

  site_name   = local.actual_site_name
  base_domain = var.base_domain
  tags        = local.common_tags
}

# S3 Website Module
module "s3_website" {
  source = "./modules/s3-website"

  site_name        = local.actual_site_name
  environment      = var.environment
  resource_prefix  = local.resource_prefix
  tags             = local.common_tags
  primary_region   = var.primary_region
  secondary_region = var.secondary_region

  providers = {
    aws      = aws
    aws.west = aws.west
  }
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"

  site_name                       = local.actual_site_name
  environment                     = var.environment
  primary_bucket_regional_domain  = module.s3_website.primary_bucket_regional_domain
  failover_bucket_regional_domain = module.s3_website.failover_bucket_regional_domain
  acm_certificate_arn             = module.acm_certificate.certificate_arn
  tags                            = local.common_tags

  depends_on = [
    module.acm_certificate
  ]
}

# Route53 Module
module "route53" {
  source = "./modules/route53"

  site_name                 = local.actual_site_name
  base_domain               = var.base_domain
  cloudfront_domain_name    = module.cloudfront.domain_name
  cloudfront_hosted_zone_id = module.cloudfront.hosted_zone_id
  tags                      = local.common_tags
}

# Separate bucket policies to avoid circular dependency
resource "aws_s3_bucket_policy" "primary_cf_access" {
  bucket = module.s3_website.primary_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_website.primary_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalListBucket"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = module.s3_website.primary_bucket_arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [
    module.s3_website,
    module.cloudfront
  ]
}

resource "aws_s3_bucket_policy" "failover_cf_access" {
  provider = aws.west
  bucket   = module.s3_website.failover_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_website.failover_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalListBucket"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = module.s3_website.failover_bucket_arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [
    module.s3_website,
    module.cloudfront
  ]
}
