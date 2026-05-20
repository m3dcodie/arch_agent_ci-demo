# =============================================================================
# STAGING / STORAGE.TF — Non-compliant resources (intentional violations)
# Expected: adag scan → FAIL
#
# Violations present:
#   ✗ public_access_block     — no aws_s3_bucket_public_access_block resource
#   ✗ encryption_at_rest      — no aws_s3_bucket_server_side_encryption_configuration
#   ✗ naming_conventions      — uppercase + underscores in bucket name
#   ✗ required_tagging        — missing Owner, Application, CostCenter
#   ✗ kms_key_rotation        — KMS key has enable_key_rotation = false
# =============================================================================

# KMS key with rotation disabled
resource "aws_kms_key" "Staging_Key_NoRotation" {  # ✗ naming_conventions
  description             = "Staging key, rotation skipped to save costs"
  deletion_window_in_days = 7
  enable_key_rotation     = false  # ✗ kms_key_rotation

  tags = {
    # ✗ required_tagging — missing Owner, Application, CostCenter
    Notes = "staging only"
  }
}

# Public S3 bucket — no encryption, no access block
resource "aws_s3_bucket" "Staging_Public_Bucket" {  # ✗ naming_conventions
  bucket = "Staging_Public_Bucket_Acme"  # ✗ naming_conventions

  tags = {
    Environment = "staging"
    # ✗ required_tagging — missing Owner, Application, CostCenter, ManagedBy
  }
}

# No aws_s3_bucket_public_access_block  → ✗ public_access_block
# No aws_s3_bucket_server_side_encryption_configuration → ✗ encryption_at_rest
