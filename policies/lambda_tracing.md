# Lambda X-Ray Tracing Policy

## Policy ID
`lambda_tracing`

## Severity
**LOW**

## Description
All AWS Lambda functions MUST have AWS X-Ray active tracing enabled. X-Ray provides end-to-end visibility into requests as they travel through distributed systems, enabling faster debugging, performance analysis, and anomaly detection in production workloads.

## Scope
This policy applies to:
- `aws_lambda_function`

## Requirements
1. **Tracing Mode:** `tracing_config.mode` must be set to `"Active"` — not `"PassThrough"` (the default)
2. **IAM Permission:** The Lambda execution role must include `xray:PutTraceSegments` and `xray:PutTelemetryRecords`

## Rationale
Active tracing is critical for:
1. **Observability:** Trace requests across Lambda, API Gateway, DynamoDB, and other services
2. **Debugging:** Identify latency bottlenecks and error sources without log diving
3. **Performance:** Measure cold start impact and downstream service latency
4. **Incident Response:** Correlate traces during outages to find root cause faster
5. **Cost Awareness:** Identify unexpectedly slow invocations driving up cost

## Examples

### ✅ Compliant — Active tracing enabled
```hcl
resource "aws_lambda_function" "prod-api-processor-v1" {
  filename      = "lambda.zip"
  function_name = "prod-api-processor-v1"
  role          = aws_iam_role.prod-api-lambda-role-execution.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  tracing_config {
    mode = "Active"   # ✓ X-Ray active tracing enabled
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team@acme.com"
    Application = "core-api"
    CostCenter  = "CC-2001"
    ManagedBy   = "terraform"
  }
}
```

### ❌ Non-Compliant — No tracing config (defaults to PassThrough)
```hcl
resource "aws_lambda_function" "processOrders" {
  filename      = "lambda.zip"
  function_name = "processOrders"
  role          = aws_iam_role.Prod_IAM_Role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  # ✗ lambda_tracing — no tracing_config block, defaults to PassThrough
}
```

### ❌ Non-Compliant — Tracing explicitly set to PassThrough
```hcl
resource "aws_lambda_function" "prod-api-processor-v1" {
  # ...
  tracing_config {
    mode = "PassThrough"  # ✗ lambda_tracing — must be "Active"
  }
}
```

## Remediation
```hcl
tracing_config {
  mode = "Active"
}
```

Also add to the Lambda execution role:
```hcl
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
```

## Exceptions
- Lambda functions used purely as CloudFormation custom resource handlers with no downstream calls

## References
- [AWS X-Ray and Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html)
- [CKV_AWS_50](https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-4)
