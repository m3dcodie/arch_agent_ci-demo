# =============================================================================
# PRODUCTION / DATABASE.TF — Compliant RDS and Aurora resources
# Expected: adag scan → PASS (0 violations)
# =============================================================================

provider "aws" {
  region = "us-east-1"
}

# KMS key for production database encryption
resource "aws_kms_key" "prod-db-kms" {
  description             = "KMS key for production database encryption"
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

# Primary RDS instance — fully compliant
resource "aws_db_instance" "prod-api-db-primary" {
  identifier        = "prod-api-db-primary"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.r6g.large"
  allocated_storage = 100

  storage_encrypted = true
  kms_key_id        = aws_kms_key.prod-db-kms.arn

  deletion_protection = true

  backup_retention_period = 14
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  multi_az            = true
  publicly_accessible = false

  skip_final_snapshot       = false
  final_snapshot_identifier = "prod-api-db-primary-final"

  tags = {
    Environment = "production"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}

# Aurora cluster for analytics — fully compliant
resource "aws_rds_cluster" "prod-analytics-cluster" {
  cluster_identifier = "prod-analytics-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "analytics"
  master_username    = "dbadmin"

  storage_encrypted = true
  kms_key_id        = aws_kms_key.prod-db-kms.arn

  deletion_protection = true

  backup_retention_period  = 14
  preferred_backup_window  = "02:00-03:00"

  skip_final_snapshot = false

  tags = {
    Environment = "production"
    Owner       = "data-team@acme.com"
    Application = "analytics-platform"
    CostCenter  = "CC-2002"
    ManagedBy   = "terraform"
  }
}
