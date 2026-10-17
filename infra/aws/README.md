# Moka — real AWS infra (Terraform)

Same shape as `../localstack` — VPC → ALB → ECS Fargate (backend, private
subnets) → RDS PostgreSQL (private subnets), ECR for the image, Secrets
Manager for every credential `env.ts` requires — plus the pieces that
directory deliberately leaves out because they only matter against a real
account:

| | `../localstack` | `./` (this directory) |
|---|---|---|
| NAT gateway | none — tasks reach ECR/Secrets Manager over LocalStack's local network | real NAT gateway, so tasks can reach Paystack/Firebase over the actual internet |
| TLS | HTTP only | ACM cert (DNS-validated) + HTTPS listener; HTTP redirects to HTTPS |
| DNS | none | Route 53 record for `domain_name`, in an existing hosted zone |
| RDS | single-AZ, `skip_final_snapshot = true` | multi-AZ by default, real final snapshot on destroy |
| ECS | 1 task, plain rolling deploy | 2+ tasks, deployment circuit breaker (auto-rollback on a bad deploy) |
| Cost | free (LocalStack) | **real, billable AWS resources** |

**This creates real infrastructure on your AWS account and will cost real
money** — mainly the NAT gateway (~$0.045/hr + data processing) and the RDS
instance. Nothing here is free-tier-safe by default. Run `terraform destroy`
when you're done poking at it if you don't want it running 24/7.

I could not run this against a live AWS account myself — this sandbox has
no network access to AWS or the Terraform registry, so there's been no real
`terraform init/plan/apply` against it. I checked every file for valid HCL
syntax and cross-referenced it against the AWS provider's resource schema,
same as the LocalStack build, but treat the first real `apply` as the actual
test — a few small things (an AZ that doesn't have your instance class
available, quota limits, etc.) are the kind of thing that only shows up
against a real account.

## Before you start

You need, already existing, by hand, before any of this:
- An AWS account with credentials configured (`aws configure`, or an
  `AWS_PROFILE`/`AWS_ACCESS_KEY_ID`+`AWS_SECRET_ACCESS_KEY` env var)
- A Route 53 hosted zone for the domain you'll point at this (e.g. you own
  `moka.example.com` and want `api.moka.example.com` to point here) — copy
  its zone ID into `hosted_zone_id`

## Deploying

```bash
cd infra/aws
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init
terraform apply   # creates VPC, NAT gateway, ALB, ACM cert, ECR, RDS, Secrets Manager entries, ECS cluster+service
```

DNS validation for the ACM cert can take a few minutes the first time —
`terraform apply` waits for it, so don't panic if it sits on
`aws_acm_certificate_validation.backend` for a while.

The ECS service will come up unhealthy on this first apply — there's no
image in the ECR repo yet:

```bash
cd ../../backend
cd ../infra/aws
ECR_URL=$(terraform output -raw ecr_repository_url)
REGION=$(terraform output -raw aws_region)
cd ../../backend
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"
docker build -t "$ECR_URL:latest" .
docker push "$ECR_URL:latest"
```

Then point Terraform at the real image and re-apply:

```bash
cd ../infra/aws
terraform apply -var="backend_image=$ECR_URL:latest"
```

Run migrations against RDS (from somewhere that can reach the private
subnet — a bastion host, an SSM-connected instance, or temporarily setting
`publicly_accessible = true` for the one-time migration and reverting it):

```bash
cd ../../backend
DATABASE_URL="postgresql://moka:<password>@$(terraform -chdir=../infra/aws output -raw rds_endpoint)/moka" \
  npx prisma migrate deploy
DATABASE_URL="postgresql://moka:<password>@$(terraform -chdir=../infra/aws output -raw rds_endpoint)/moka" \
  npx prisma db seed
```

Point the Flutter app's `API_BASE_URL` and the backend's
`PLATFORM_CALLBACK_URL` at:
```bash
terraform output api_url
```

## Choosing LocalStack vs. real AWS

The two directories are fully independent Terraform states — nothing here
reads or shares state with `../localstack`. Use whichever fits what you're
doing right now:
- `../localstack` — free, fast, safe to `apply`/`destroy` repeatedly while
  you're learning or iterating on the Terraform itself
- `./` (this one) — the version that's actually reachable from a real
  phone/device over the internet, once you're ready to pay for that

You can have both applied at the same time (they don't conflict — different
provider endpoints, different state files) and just point the Flutter app's
`API_BASE_URL` at whichever backend you want to test against that day.

## What to harden before this is a real production deploy

- Move Terraform state to an S3 backend + DynamoDB lock table (see the
  commented-out `backend "s3"` block in `versions.tf`) instead of local state
  — required the moment more than one person applies this.
- `deletion_protection = false` on the RDS instance — flip it true once this
  holds real user data.
- One NAT gateway (single AZ) — a NAT gateway per AZ removes the single
  point of failure, at extra cost.
- No WAF in front of the ALB yet.
- CloudWatch alarms (ECS service unhealthy, RDS CPU/storage, ALB 5xx rate) —
  nothing here pages anyone if something breaks at 3am.
