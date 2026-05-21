# =============================================================================
# STAGING / STORAGE.TF — All violations resolved
# Expected: adag scan → PASS (0 violations)
# =============================================================================

resource "aws_kms_key" "staging-app-kms" {
  description             = "Staging KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "staging"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "staging-app-assets" {
  bucket = "staging-app-assets-acme"

  tags = {
    Environment = "staging"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "staging-app-assets" {
  bucket = aws_s3_bucket.staging-app-assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging-app-assets" {
  bucket = aws_s3_bucket.staging-app-assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.staging-app-kms.arn
    }
  }
}
