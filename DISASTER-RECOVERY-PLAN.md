# Disaster Recovery Plan

Live domain: **invest-iq.online** (audit templates referencing planmyjourney.com are not deployed).

## RTO and RPO

### Production

| Component | RTO | RPO |
|-----------|-----|-----|
| Frontend (CloudFront + S3) | 15 min | 5 min |
| API (EKS + KGateway NLB) | 30 min | 0 (stateless) |
| Database (RDS PostgreSQL) | 1 hour | 5 min |
| Async jobs (SQS + DynamoDB) | 30 min | 0 (queue retained) |
| Overall | 1 hour | 5 min |

### Dev

| Component | RTO | RPO |
|-----------|-----|-----|
| Overall | 4 hours | 1 hour |

## Backup Schedule

| Resource | Method | Retention |
|----------|--------|-----------|
| S3 frontend | Versioning + lifecycle (90-day noncurrent) | 90 days |
| RDS | Automated snapshots | 30 days (after terraform apply) |
| DynamoDB jobs | PITR (when table exists) | 35 days |
| Kubernetes | Daily export via `scripts/backup-strategy.sh` | Per S3 lifecycle |

## Restore Procedures

1. Run `scripts/restore-strategy.sh BACKUP_DATE prod`
2. Fix Route53 if NLB changed: `scripts/update-route53-gateway.ps1`
3. ArgoCD sync: `scripts/argocd-sync-all.ps1`
4. Verify health endpoints before traffic cutover

## Testing

- **Monthly:** Restore RDS/DynamoDB to `*-restored` identifiers
- **Quarterly:** Full DR drill including Route53 validation
- **On-demand:** Emergency restore from latest snapshot

## Critical Operational Fixes (from audit)

1. **Route53:** `api.invest-iq.online` currently points to legacy ALB — run `update-route53-gateway.ps1`
2. **NLB TLS:** Apply gateway GitOps changes for port 443 + ACM termination
3. **Legacy ALBs:** Remove via `cleanup-unused-aws-resources.ps1` after Route53 fix
4. **Terraform apply:** Enables WAF, RDS backups, disables legacy ALB

## Contacts

- On-call: tkpreethi973@gmail.com
- FinOps alerts: tkp4762@gmail.com
