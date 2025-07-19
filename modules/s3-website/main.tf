# Null resource to empty logs bucket before deletion
resource "null_resource" "empty_logs_bucket" {
  triggers = {
    bucket_name = "${var.resource_prefix}-site-logs"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Emptying S3 bucket ${self.triggers.bucket_name}..."
      aws s3 rm s3://${self.triggers.bucket_name} --recursive || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      echo "Bucket ${self.triggers.bucket_name} emptied."
    EOT
  }
}

# Logs bucket
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.resource_prefix}-site-logs"
  force_destroy = true
  tags          = merge(var.tags, { Name = "${var.resource_prefix}-site-logs" })

  depends_on = [null_resource.empty_logs_bucket]
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logfile-cleanup"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    expiration {
      days = 90
    }
  }
}

# Block all public access to logs bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Null resource to empty main website bucket before deletion
resource "null_resource" "empty_www_bucket" {
  triggers = {
    bucket_name = "www.${var.site_name}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Emptying S3 bucket ${self.triggers.bucket_name}..."
      aws s3 rm s3://${self.triggers.bucket_name} --recursive || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      echo "Bucket ${self.triggers.bucket_name} emptied."
    EOT
  }
}

# Primary website bucket
resource "aws_s3_bucket" "www_site" {
  bucket        = "www.${var.site_name}"
  force_destroy = true
  tags          = merge(var.tags, { Name = "www.${var.site_name}" })

  depends_on = [null_resource.empty_www_bucket]
}

resource "aws_s3_bucket_versioning" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "www_site" {
  bucket        = aws_s3_bucket.www_site.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "www.${var.site_name}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "www_site" {
  bucket = aws_s3_bucket.www_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Intelligent tiering for cost optimization
resource "aws_s3_bucket_intelligent_tiering_configuration" "www_site_tiering" {
  bucket = aws_s3_bucket.www_site.id
  name   = "EntireBucket"

  status = "Enabled"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}

# Block all public access to primary website bucket
resource "aws_s3_bucket_public_access_block" "www_site" {
  bucket = aws_s3_bucket.www_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Null resource to empty secondary bucket before deletion
resource "null_resource" "empty_destination_bucket" {
  triggers = {
    bucket_name = "${var.resource_prefix}-secondary"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Emptying S3 bucket ${self.triggers.bucket_name} in us-west-1..."
      aws s3 rm s3://${self.triggers.bucket_name} --recursive --region us-west-1 || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --region us-west-1 --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --region us-west-1 --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      aws s3api delete-objects --bucket ${self.triggers.bucket_name} --region us-west-1 --delete "$(aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --region us-west-1 --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' 2>/dev/null)" || true
      echo "Bucket ${self.triggers.bucket_name} emptied."
    EOT
  }
}

# Failover bucket (secondary region)
resource "aws_s3_bucket" "destination" {
  provider      = aws.west
  bucket        = "${var.resource_prefix}-secondary"
  force_destroy = true
  tags          = merge(var.tags, { Name = "${var.resource_prefix}-secondary" })

  depends_on = [null_resource.empty_destination_bucket]
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access to secondary website bucket
resource "aws_s3_bucket_public_access_block" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# IAM Role for replication
resource "aws_iam_role" "replication" {
  name = "${var.resource_prefix}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Null resource to clean up any instance profile associations before deleting IAM role
resource "null_resource" "cleanup_replication_role" {
  triggers = {
    role_name = aws_iam_role.replication.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up instance profiles for role ${self.triggers.role_name}..."
      # List and remove role from any instance profiles
      INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name ${self.triggers.role_name} --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null || true)
      for profile in $INSTANCE_PROFILES; do
        echo "Removing role ${self.triggers.role_name} from instance profile $profile"
        aws iam remove-role-from-instance-profile --instance-profile-name $profile --role-name ${self.triggers.role_name} || true
      done
      echo "Instance profile cleanup completed for role ${self.triggers.role_name}"
    EOT
  }

  depends_on = [aws_iam_role.replication]
}

# IAM Policy for replication
resource "aws_iam_policy" "replication" {
  name = "${var.resource_prefix}-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.www_site.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.www_site.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Configure replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [
    aws_s3_bucket_versioning.www_site,
    aws_s3_bucket_versioning.destination
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.www_site.id

  rule {
    id     = "Full-Replication-Rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}

# Note: Bucket policies are now managed in the root main.tf to avoid circular dependencies
