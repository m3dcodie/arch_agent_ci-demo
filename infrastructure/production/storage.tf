# =============================================================================
# PRODUCTION / STORAGE.TF — Compliant S3 resources
# Expected: adag scan → PASS (0 violations)
# =============================================================================

# KMS key for S3 encryption
resource "aws_kms_key" "prod-s3-kms" {
  description             = "KMS key for production S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = "production"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}

# Compliant S3 bucket — private, encrypted, blocked public access
resource "aws_s3_bucket" "prod-app-assets" {
  bucket = "prod-app-assets-acme"

  tags = {
    Environment = "production"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "prod-app-assets" {
  bucket = aws_s3_bucket.prod-app-assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod-app-assets" {
  bucket = aws_s3_bucket.prod-app-assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.prod-s3-kms.arn
    }
  }
}
