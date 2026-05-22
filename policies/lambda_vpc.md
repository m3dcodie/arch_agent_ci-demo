# Lambda VPC Deployment Policy

## Policy ID
`lambda_vpc`

## Severity
**MEDIUM**

## Description
All AWS Lambda functions MUST be deployed inside a VPC to ensure network isolation, prevent direct internet exposure, and enable access to private resources such as RDS databases, ElastiCache clusters, and internal services. Lambda functions running outside a VPC are directly internet-accessible and cannot reach private network resources.

## Scope
This policy applies to:
- `aws_lambda_function`

## Requirements
1. **VPC Configuration:** Every Lambda function must define a `vpc_config` block
2. **Subnets:** Must reference at least one private subnet
3. **Security Groups:** Must reference at least one security group scoped to least privilege
4. **Private Subnets Only:** Lambda should not be placed in public subnets

## Rationale
VPC deployment is critical for:
1. **Network Isolation:** Prevent direct internet exposure of function execution
2. **Private Resource Access:** Reach RDS, ElastiCache, and internal APIs without NAT
3. **Security Boundaries:** Apply security group rules to control inbound/outbound traffic
4. **Compliance:** Required by PCI-DSS, HIPAA, and SOC 2 for workloads handling sensitive data
5. **Blast Radius:** Limit the impact of a compromised function

## Examples

### ✅ Compliant — Lambda inside a VPC
```hcl
resource "aws_lambda_function" "prod-api-processor-v1" {
  filename      = "lambda.zip"
  function_name = "prod-api-processor-v1"
  role          = aws_iam_role.prod-api-lambda-role-execution.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  vpc_config {                                      # ✓ VPC deployment
    subnet_ids         = aws_subnet.private[*].id   # ✓ private subnets
    security_group_ids = [aws_security_group.prod-api-sg-lambda.id]
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

### ❌ Non-Compliant — Lambda with no VPC config
```hcl
resource "aws_lambda_function" "processOrders" {
  filename      = "lambda.zip"
  function_name = "processOrders"
  role          = aws_iam_role.Prod_IAM_Role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  # ✗ lambda_vpc — no vpc_config block, function runs outside any VPC
}
```

## Remediation
```hcl
vpc_config {
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.lambda_sg.id]
}
```

## Exceptions
- Lambda@Edge functions (CloudFront-triggered) — cannot be VPC-deployed by AWS design
- One-off utility scripts with no access to private resources and no sensitive data handling

## References
- [AWS Lambda VPC Configuration](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html)
- [CKV_AWS_117](https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-inside-a-vpc-1)
