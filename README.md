# arch_agent_ci-demo

Demo repository for [ADAG](https://github.com/m3dcodie/arch_agent) — AI-Driven Architecture Guardrail.

This repo shows ADAG running as a GitHub Actions CI gate: every pull request that touches a Terraform file is automatically scanned for governance violations. Violations block the PR and are reported inline via the GitHub Security tab (SARIF) and as a PR comment.

## What's in here

```
infrastructure/
├── production/       # ✓ Compliant — all policies satisfied
│   ├── database.tf   # RDS + Aurora with encryption, deletion protection, multi-AZ
│   ├── storage.tf    # S3 with public access block + KMS encryption
│   └── kms.tf        # KMS keys with rotation enabled
└── staging/          # ✗ Intentional violations — for demo purposes
    ├── database.tf   # Missing delete_protection, encryption, backup, multi_az, tags
    └── storage.tf    # Public bucket, no encryption, bad naming, KMS rotation off

policies/             # 10 governance policies checked by ADAG
.github/workflows/
└── adag-scan.yml     # CI pipeline — runs on every PR touching *.tf files
```

## How the CI demo works

1. Open a pull request that modifies any file under `infrastructure/`
2. The `ADAG — Terraform Governance Scan` workflow triggers automatically
3. ADAG scans all `.tf` files against the 10 policies in `policies/`
4. Results are posted as a PR comment and uploaded to the GitHub Security tab
5. If violations are found the check fails — the PR is blocked

## Try it yourself

**Scenario A — clean PR (should pass):**
Edit `infrastructure/production/database.tf`, e.g. bump `engine_version`. No violations → green check.

**Scenario B — dirty PR (should fail):**
Edit `infrastructure/staging/database.tf`, e.g. add a new non-compliant resource. Violations → red check + comment.

## Setup

### 1. Add the required secret

In your GitHub repo → **Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|---|---|
| `GH_MODELS_TOKEN` | A fine-grained PAT with **GitHub Copilot → Read** and **Models → Read** permissions |

Create the token at: https://github.com/settings/personal-access-tokens/new

### 2. Run locally

```bash
pip install adag
cp .env.example .env   # fill in your token and absolute POLICIES_DIR path
adag scan ./infrastructure/
```

## Policies enforced

| Policy | What it checks |
|---|---|
| `delete_protection` | RDS/Aurora must have `deletion_protection = true` |
| `encryption_at_rest` | Storage resources must be encrypted |
| `backup_retention` | RDS backup retention ≥ 7 days |
| `automated_backups_enabled` | `backup_retention_period` must be > 0 |
| `multi_az_requirement` | Production RDS must be multi-AZ |
| `public_access_block` | S3 buckets must block public access |
| `required_tagging` | Resources must have Environment, Owner, Application, CostCenter tags |
| `naming_conventions` | Resource names must use kebab-case (no uppercase or underscores) |
| `allowed_regions` | AWS provider region must be in the approved list |
| `kms_key_rotation` | KMS keys must have `enable_key_rotation = true` |

---

Powered by [ADAG](https://github.com/m3dcodie/arch_agent)
