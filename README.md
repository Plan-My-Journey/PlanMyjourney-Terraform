# Plan My Journey — Terraform

Infrastructure as Code for AWS (Track A: EKS).

Organization: [Plan-My-Journey](https://github.com/orgs/Plan-My-Journey)

## Modules

| Module | Resources |
|---|---|
| `modules/vpc` | Multi-AZ VPC, public/private/database subnets |
| `modules/eks` | EKS 1.30+, managed node groups, OIDC, IRSA for EBS CSI |
| `modules/irsa` | Pod IAM roles (Bedrock, Secrets Manager) |
| `modules/rds` | PostgreSQL RDS |
| `modules/ecr` | Container registries |
| `modules/cognito` | User Pool, App Client, Hosted UI domain |
| `modules/frontend-hosting` | S3 + CloudFront + ACM |
| `modules/monitoring` | CloudWatch, SNS alarms |
| `modules/iam` | GitHub OIDC roles |

## Environments

```bash
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform plan -var-file=environments/prod.tfvars
```

## Remote State

S3 backend with DynamoDB locking (`backend.tf`).

## GitOps

Kubernetes deployments are managed by **ArgoCD** from the [planmyjourney-gitops](https://github.com/Plan-My-Journey/planmyjourney-gitops) repository — not Flux.
