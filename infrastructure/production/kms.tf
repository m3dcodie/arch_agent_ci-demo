# =============================================================================
# PRODUCTION / KMS.TF — Compliant KMS keys
# Expected: adag scan → PASS (0 violations)
# =============================================================================

# Application secrets encryption key
resource "aws_kms_key" "prod-secrets-kms" {
  description             = "KMS key for application secrets and config encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = "production"
    Owner       = "security-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-3001"
    ManagedBy   = "terraform"
  }
}

# Audit log encryption key
resource "aws_kms_key" "prod-audit-kms" {
  description             = "KMS key for audit log encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = "production"
    Owner       = "security-team@acme.com"
    Application = "audit-service"
    CostCenter  = "CC-3001"
    ManagedBy   = "terraform"
  }
}
