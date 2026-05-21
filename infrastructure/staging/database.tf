# =============================================================================
# STAGING / DATABASE.TF — Non-compliant resources (intentional violations)
# Expected: adag scan → FAIL
#
# Violations present:
#   ✓ delete_protection       — FIXED (deletion_protection = true)
#   ✓ encryption_at_rest      — FIXED (storage_encrypted = true)
#   ✗ backup_retention        — backup_retention_period = 0
#   ✗ automated_backups       — backup_retention_period = 0
#   ✗ multi_az_requirement    — multi_az = false on a production-tagged resource
#   ✓ public_access_block     — FIXED (publicly_accessible = false)
#   ✗ required_tagging        — missing Owner, Application, CostCenter
#   ✗ naming_conventions      — underscores + uppercase in resource name
# =============================================================================

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "staging_DB_Unprotected" {
  identifier        = "staging_DB_Unprotected"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  storage_encrypted   = true
  deletion_protection = true

  backup_retention_period = 0 # ✗ backup_retention + automated_backups_enabled

  multi_az            = false # ✗ multi_az_requirement
  publicly_accessible = false

  skip_final_snapshot = true

  username = "admin"
  password = "changeme123"

  tags = {
    Environment = "production" # tagged production but violates all production policies
    # ✗ required_tagging — missing Owner, Application, CostCenter, ManagedBy
  }
}
