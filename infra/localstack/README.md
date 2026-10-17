# Moka — LocalStack infra (Terraform)

VPC → public ALB → ECS Fargate (backend, private subnets) → RDS PostgreSQL
(private subnets), plus ECR for the image and Secrets Manager for every
credential `env.ts` requires.

## Before you start

LocalStack's standalone anonymous "Community" image is now legacy — you need
a free account (the "Hobby" plan is free for non-commercial use) to run even
the no-cost tier going forward. This changed after my training cutoff was
set, so double-check current signup/licensing steps at
https://docs.localstack.cloud/getting-started/installation/ before you spend
time debugging what might just be an auth issue. I couldn't verify this
end-to-end myself — this sandbox has no Docker and no network access to
LocalStack or the Terraform registry, so none of this Terraform has been run
with a real `terraform init/plan/apply`. I did check every file for valid
HCL syntax (via a standalone HCL parser), so what you're getting is
syntactically sound and structurally consistent with the AWS provider's
resource schema — but the first real `terraform apply` against a live
LocalStack container is the real test. Expect to fix a few small things.

```bash
pip install localstack   # or: brew install localstack/tap/localstack-cli
localstack auth set-token <your-token>   # from your free LocalStack account
localstack start -d
```

## Deploying

```bash
cd infra/localstack
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init
terraform apply   # creates VPC, ALB, ECR, RDS, Secrets Manager entries, ECS cluster+service
```

The ECS service will come up unhealthy on this first apply — there's no
image in the ECR repo yet. Build and push one:

```bash
cd ../../backend
ECR_URL=$(cd ../infra/localstack && terraform output -raw ecr_repository_url)
aws --endpoint-url=http://localhost:4566 ecr get-login-password | \
  docker login --username AWS --password-stdin "$ECR_URL"
docker build -t "$ECR_URL:latest" .
docker push "$ECR_URL:latest"
```

Then point Terraform at the real image and re-apply:

```bash
cd ../infra/localstack
terraform apply -var="backend_image=$ECR_URL:latest"
```

Run migrations against the now-running RDS instance (same command as local
dev, just against the RDS endpoint instead of the docker-compose Postgres):

```bash
cd ../../backend
DATABASE_URL="postgresql://moka:<password>@$(terraform -chdir=../infra/localstack output -raw rds_endpoint)/moka" \
  npx prisma migrate deploy
DATABASE_URL="postgresql://moka:<password>@$(terraform -chdir=../infra/localstack output -raw rds_endpoint)/moka" \
  npx prisma db seed
```

Get the API's address:
```bash
terraform output alb_dns_name
```
Point the Flutter apps' `API_BASE_URL` and the backend's
`PLATFORM_CALLBACK_URL` at that.

## What's deliberately different from a real-AWS build

- **No NAT gateway.** Private-subnet tasks reach ECR/Secrets Manager through
  LocalStack's local network, not real internet egress. A real deployment
  needs a NAT gateway so the backend can actually reach Paystack's and
  Firebase's real APIs — that goes in the (separate, not-yet-built) real-AWS
  Terraform directory.
- **No HTTPS listener / ACM cert / Route 53 record.** Not worth the friction
  in LocalStack; the real build terminates TLS at the ALB.
- **`skip_final_snapshot = true` on RDS.** Fine for throwaway local infra,
  wrong for anything real — flip it before you ever run this against
  production data.
- **Single-AZ RDS, one Fargate task.** No redundancy — deliberately minimal
  for local iteration cost/complexity, not a production HA posture.

## Next: the real-AWS build

`../aws` is that build — same architecture, plus a NAT gateway, HTTPS/ACM,
multi-AZ RDS, and a real snapshot policy. It's a separate Terraform state
in its own directory (not this one pointed at real AWS), so you can keep
using this LocalStack build for iteration and only reach for `../aws` when
you actually want something reachable from a real device.
