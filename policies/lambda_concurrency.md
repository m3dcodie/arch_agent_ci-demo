# Lambda Concurrency Limit Policy

## Policy ID
`lambda_concurrency`

## Severity
**MEDIUM**

## Description
All AWS Lambda functions MUST define a reserved concurrency limit. Without a limit, a single runaway function can consume the entire account-level concurrency pool (default 1000), starving all other Lambda functions in the account. Reserved concurrency acts as both a ceiling (prevent runaway scaling) and a guarantee (reserve capacity for critical functions).

## Scope
This policy applies to:
- `aws_lambda_function`

## Requirements
1. **Reserved Concurrency:** Every function must set `reserved_concurrent_executions` to a value greater than `-1`
2. **Value of 0:** Acceptable only for intentionally disabled functions (deploy-paused state)
3. **Sizing:** Value must be justified based on expected peak load — do not default to account maximum

## Rationale
Concurrency limits are critical for:
1. **Blast Radius:** A bug causing infinite invocations cannot take down other functions
2. **Downstream Protection:** Prevent Lambda from overwhelming databases or APIs with connections
3. **Cost Control:** Uncapped functions can generate unexpected cost spikes
4. **Account Stability:** Preserve concurrency headroom for other workloads
5. **Predictability:** SLAs require knowing the maximum parallel execution count

## Examples

### ✅ Compliant — Reserved concurrency set
```hcl
resource "aws_lambda_function" "prod-api-processor-v1" {
  filename      = "lambda.zip"
  function_name = "prod-api-processor-v1"
  role          = aws_iam_role.prod-api-lambda-role-execution.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  reserved_concurrent_executions = 100   # ✓ capped at 100 parallel executions

  tags = {
    Environment = "production"
    Owner       = "platform-team@acme.com"
    Application = "core-api"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}
```

### ✅ Compliant — Function intentionally disabled
```hcl
resource "aws_lambda_function" "staging-batch-archiver-v1" {
  # ...
  reserved_concurrent_executions = 0   # ✓ intentionally disabled during off-peak
}
```

### ❌ Non-Compliant — No concurrency limit set
```hcl
resource "aws_lambda_function" "processOrders" {
  filename      = "lambda.zip"
  function_name = "processOrders"
  role          = aws_iam_role.Prod_IAM_Role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  # ✗ lambda_concurrency — no reserved_concurrent_executions defined
  # defaults to -1 (unreserved), consuming from shared account pool
}
```

### ❌ Non-Compliant — Unreserved explicitly
```hcl
resource "aws_lambda_function" "prod-api-processor-v1" {
  # ...
  reserved_concurrent_executions = -1  # ✗ lambda_concurrency — explicitly unreserved
}
```

## Remediation
```hcl
reserved_concurrent_executions = 50   # Set based on expected peak load
```

To calculate an appropriate value:
- Estimate peak requests per second
- Multiply by average function duration in seconds
- Add 20% headroom
- Example: 40 req/s × 0.5s avg = 20, +20% = 24 → set to 25

## Exceptions
- Event-driven functions with truly unpredictable burst requirements may use provisioned concurrency instead
- Document any exception with a `ConcurrencyException` tag and approval

```hcl
tags = {
  ConcurrencyException = "true"
  ExceptionReason      = "Unpredictable burst — using provisioned concurrency instead"
  ApprovedBy           = "platform-team@acme.com"
}
```

## References
- [AWS Lambda Reserved Concurrency](https://docs.aws.amazon.com/lambda/latest/dg/configuration-concurrency.html)
- [CKV_AWS_115](https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-function-level-concurrent-execution-limit)
