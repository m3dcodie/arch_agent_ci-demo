# =============================================================================
# STAGING / DATABASE.TF — All violations resolved
# Expected: adag scan → PASS (0 violations)
# =============================================================================

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "staging-db-primary" {
  identifier        = "staging-db-primary"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  storage_encrypted   = true
  deletion_protection = true

  backup_retention_period = 7

  multi_az            = true
  publicly_accessible = false

  skip_final_snapshot = true

  username = "admin"
  password = "changeme123"

  tags = {
    Environment = "staging"
    Owner       = "platform-team@acme.com"
    Application = "core-platform"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}
