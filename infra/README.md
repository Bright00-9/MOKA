# Moka infra

Two independent Terraform builds of the same architecture (VPC → ALB → ECS
Fargate → RDS, plus ECR + Secrets Manager) — pick whichever fits what you're
doing right now, or run both at once, since they're separate state and don't
touch each other:

- **`localstack/`** — free, runs entirely against a local LocalStack
  container. Safe to `apply`/`destroy` repeatedly while you're learning
  Terraform or the AWS services themselves. Nothing here is reachable from
  outside your machine.
- **`aws/`** — the same shape, plus what only makes sense against a real
  account: a NAT gateway (real internet egress), an ACM cert + HTTPS (via a
  domain you own in Route 53), multi-AZ RDS, and a real snapshot-on-destroy
  policy. **Creates real, billable AWS resources.**

See each directory's own README for exact deploy steps. The short version:

```bash
cd infra/localstack   # or: cd infra/aws
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Then point the Flutter app's `API_BASE_URL` (and the backend's
`PLATFORM_CALLBACK_URL`) at whichever one's output you want to test against
— `alb_dns_name` for LocalStack, `api_url` for real AWS.
