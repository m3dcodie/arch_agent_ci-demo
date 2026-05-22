# =============================================================================
# STAGING / IAM.TF — Org-policy violations: checkov vs adag comparison
# Expected: checkov → FAIL (IAM wildcard + generic Lambda security gaps)
#           adag    → FAIL (all of the above + every org-specific violation below)
#
# Violations checkov catches (security misconfigurations):
#   ✗ iam_least_privilege     — Action: "*" + Resource: "*" (CKV_AWS_288/289/355, CKV2_AWS_40)
#   ✗ lambda_vpc              — Lambda not deployed inside a VPC (CKV_AWS_117)
#   ✗ lambda_tracing          — X-Ray tracing not enabled (CKV_AWS_50)
#   ✗ lambda_concurrency      — No function-level concurrency limit (CKV_AWS_115)
#
# Violations ONLY adag catches (organisational policies — invisible to checkov):
#   ✗ naming_conventions      — uppercase + underscores in role/policy names
#   ✗ naming_conventions      — missing <env>-<app>-<service>-role-<purpose> pattern
#   ✗ naming_conventions      — camelCase function_name, no environment prefix
#   ✗ required_tagging        — Environment = "prod" (must be "production")
#   ✗ required_tagging        — Owner = "john" (must be a valid email address)
#   ✗ required_tagging        — CostCenter = "1234" (must match CC-XXXX format)
#   ✗ required_tagging        — Owner = "data team" (spaces not allowed, must be email)
#   ✗ required_tagging        — CostCenter = "CC-12" (must be 4 digits: CC-XXXX)
#   ✗ required_tagging        — missing Application, ManagedBy tags
#   ✗ allowed_regions         — ap-south-1 (Mumbai) not in approved region list
# =============================================================================

# Unapproved region — adag flags this; checkov has no concept of org allowlists
# ✗ allowed_regions: ap-south-1 is not in the approved list
provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}

# -----------------------------------------------------------------------------
# Resource 1: IAM Role
# checkov catches: nothing on the role itself
# adag catches:    naming_conventions, required_tagging (format + missing keys)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "Prod_IAM_Role" {                # ✗ naming_conventions — uppercase + underscores
  name = "Prod_IAM_Role"                                 # ✗ naming_conventions — must be prod-<app>-<svc>-role-<purpose>

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Environment = "prod"    # ✗ required_tagging — invalid value (must be "production")
    Owner       = "john"    # ✗ required_tagging — not a valid email address
    CostCenter  = "1234"    # ✗ required_tagging — missing CC- prefix (must be CC-XXXX)
    # ✗ required_tagging — missing Application
    # ✗ required_tagging — missing ManagedBy
  }
}

# -----------------------------------------------------------------------------
# Resource 2: Inline policy — full admin wildcard
# checkov catches: iam_least_privilege (Action: * + Resource: *)
# adag catches:    iam_least_privilege + naming_conventions (camelCase, no env prefix)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "myAdminPolicy" {         # ✗ naming_conventions — camelCase, no env prefix
  name = "myAdminPolicy"                                 # ✗ naming_conventions — must follow env-app-svc-purpose pattern
  role = aws_iam_role.Prod_IAM_Role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"      # ✗ iam_least_privilege — full admin (checkov + adag)
        Resource = "*"      # ✗ iam_least_privilege — wildcard resource (checkov + adag)
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Resource 3: Lambda in unapproved region, bad name, bad tags
# checkov catches: nothing (no security misconfiguration)
# adag catches:    allowed_regions, naming_conventions, required_tagging (format)
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "processOrders" {         # ✗ naming_conventions — camelCase, no env-app prefix
  provider      = aws.mumbai                             # ✗ allowed_regions — ap-south-1 not approved
  filename      = "lambda.zip"
  function_name = "processOrders"                        # ✗ naming_conventions — must be staging-<app>-<fn>-<ver>
  role          = aws_iam_role.Prod_IAM_Role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  tags = {
    Environment = "production"   # claims production, but deployed in an unapproved region
    Owner       = "data team"    # ✗ required_tagging — spaces not allowed, must be email
    Application = "Orders"       # ✗ required_tagging — must be lowercase hyphen-separated
    CostCenter  = "CC-12"        # ✗ required_tagging — must be 4 digits (CC-XXXX)
    # ✗ required_tagging — missing ManagedBy
  }
}
