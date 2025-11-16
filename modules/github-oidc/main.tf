# Data source to get current AWS account info
data "aws_caller_identity" "current" {}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub's OIDC thumbprints (official values from GitHub documentation)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(var.tags, {
    Name       = "${var.project_name}-github-oidc-provider"
    SubService = "github-oidc-provider"
  })
}

# IAM Role for GitHub Actions with project-specific naming
resource "aws_iam_role" "github_actions_role" {
  name = "GithubActionsOIDC-${var.project_name}-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name       = "GithubActionsOIDC-${var.project_name}-Role"
    SubService = "github-actions-role"
  })
}

# Project-specific IAM Policy with least privilege permissions
resource "aws_iam_policy" "github_actions_policy" {
  name        = "GithubActions-${var.project_name}-Policy"
  description = "Least privilege policy for GitHub Actions deployment of ${var.project_name}"

  # Prevent tagging conflicts during policy updates
  lifecycle {
    ignore_changes = [tags]
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 permissions for website buckets and state management
      {
        Sid    = "S3WebsiteManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucket*",
          "s3:ListBucket*",
          "s3:PutBucket*",
          "s3:DeleteBucket*",
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject*",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:GetAccelerateConfiguration",
          "s3:PutAccelerateConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:PutReplicationConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetIntelligentTieringConfiguration",
          "s3:PutIntelligentTieringConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::*${var.project_name}*",
          "arn:aws:s3:::*${var.project_name}*/*",
          "arn:aws:s3:::*lawnsmartapp*",
          "arn:aws:s3:::*lawnsmartapp*/*"
        ]
      },
      # CloudFront permissions
      {
        Sid    = "CloudFrontManagement"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution*",
          "cloudfront:ListDistributions",
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl*",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:CreateResponseHeadersPolicy",
          "cloudfront:DeleteResponseHeadersPolicy",
          "cloudfront:GetResponseHeadersPolicy",
          "cloudfront:UpdateResponseHeadersPolicy",
          "cloudfront:ListResponseHeadersPolicies",
          "cloudfront:ListTagsForResource",
          "cloudfront:TagResource",
          "cloudfront:UntagResource"
        ]
        Resource = "*"
      },
      # Route53 permissions
      {
        Sid    = "Route53Management"
        Effect = "Allow"
        Action = [
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHostedZone",
          "route53:ListHostedZones*",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:ChangeTagsForResource"
        ]
        Resource = "*"
      },
      # ACM permissions
      {
        Sid    = "ACMManagement"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:ListTagsForCertificate"
        ]
        Resource = "*"
      },
      # DynamoDB permissions for state locking
      {
        Sid    = "DynamoDBStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:ListTables"
        ]
        Resource = [
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/*terraform*lock*",
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/*${var.project_name}*"
        ]
      },
      # CloudWatch permissions for monitoring
      {
        Sid    = "CloudWatchManagement"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLog*"
        ]
        Resource = "*"
      },
      # Limited IAM permissions for service roles only
      {
        Sid    = "IAMServiceRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy*",
          "iam:ListPolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:ListRolePolicies",
          "iam:ListPolicyVersions",
          "iam:DeletePolicyVersion",
          "iam:ListInstanceProfilesForRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider"
        ]
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:role/*replication*",
          "arn:aws:iam::${var.aws_account_id}:role/*${var.project_name}*",
          "arn:aws:iam::${var.aws_account_id}:policy/*replication*",
          "arn:aws:iam::${var.aws_account_id}:policy/*${var.project_name}*",
          "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name       = "GithubActions-${var.project_name}-Policy"
    SubService = "github-actions-policy"
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}