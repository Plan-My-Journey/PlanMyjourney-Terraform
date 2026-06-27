# Terraform State Reconciliation Runbook

> Status: **pending** — must be run once, interactively, in a controlled session.
> Findings captured 2026-06-27 against `prod/terraform.tfstate`.

This repo has an **in-progress refactor** sitting in the working tree:

1. **RDS networking move** — `aws_db_subnet_group.main` + `aws_security_group.rds`
   relocated from `module.vpc` into `module.rds`.
2. **RDS alarm consolidation** — the three `aws_cloudwatch_metric_alarm` resources
   (`rds_cpu_high`, `rds_connections_high`, `rds_storage_low`) removed from
   `module.rds`; the canonical copies live in `module.monitoring` (count-gated by
   `enable_rds_alarms`).
3. **Backend lock migration** — `backend.tf` switches from a DynamoDB lock table
   (`dynamodb_table`) to S3 native locking (`use_lockfile = true`).

## The problem: duplicate state entries

The live state records the **same physical AWS resource under two addresses**.
A `moved` block cannot fix this — its destination is already occupied, so the
move (and any plain `moved.tf`) **errors out**. These must be reconciled with
`terraform state rm`, which edits state only and does **not** touch AWS.

| Real resource (one in AWS) | Keep this address | `state rm` this stale duplicate |
|---|---|---|
| RDS subnet group | `module.rds.aws_db_subnet_group.main` | `module.vpc.aws_db_subnet_group.main` |
| RDS security group | `module.rds.aws_security_group.rds` | `module.vpc.aws_security_group.rds` |
| alarm `ai-travel-rds-cpu-high-prod` | `module.monitoring.aws_cloudwatch_metric_alarm.rds_cpu_high[0]` | `module.rds.aws_cloudwatch_metric_alarm.rds_cpu_high` |
| alarm `ai-travel-rds-connections-high-prod` | `module.monitoring.aws_cloudwatch_metric_alarm.rds_connections_high[0]` | `module.rds.aws_cloudwatch_metric_alarm.rds_connections_high` |
| alarm `ai-travel-rds-storage-low-prod` | `module.monitoring.aws_cloudwatch_metric_alarm.rds_storage_low[0]` | `module.rds.aws_cloudwatch_metric_alarm.rds_storage_low` |

## Procedure (run once, in order)

```bash
# 0. Pre-flight: back up state
aws s3 cp s3://ai-travel-terraform-state-235270183260/prod/terraform.tfstate \
          ./terraform.tfstate.backup-$(date +%Y%m%d)

# 1. Complete the backend lock migration (interactive — answer "yes" to migrate)
terraform init -migrate-state

# 2. Drop the stale duplicate state entries (edits state only; AWS untouched)
terraform state rm \
  module.vpc.aws_db_subnet_group.main \
  module.vpc.aws_security_group.rds \
  module.rds.aws_cloudwatch_metric_alarm.rds_cpu_high \
  module.rds.aws_cloudwatch_metric_alarm.rds_connections_high \
  module.rds.aws_cloudwatch_metric_alarm.rds_storage_low

# 3. Confirm a clean plan
terraform plan
```

## What `terraform plan` should show after step 2

- ✅ RDS subnet group / security group — **no change** (now solely under `module.rds`).
- ✅ 3 RDS alarms — **no change** (solely under `module.monitoring[0]`).
- ✅ `module.alb.*` — refreshes as already-deleted (the legacy ALB was removed
  out-of-band; `enable_legacy_alb = false`) and drops from state. Self-heals.
- ✅ `module.monitoring.aws_cloudwatch_metric_alarm.alb_*[0]` — destroyed
  (`enable_alb_alarms = enable_legacy_alb = false`); these are orphaned, the ALB is gone.

## Expected real changes to confirm before applying

- ⚠️ `module.monitoring.aws_cloudwatch_log_group.cloudtrail` is **removed from
  config** → it will be **destroyed**. Confirm this is intended.

## Why not `moved` blocks

`moved { from = module.vpc.X  to = module.rds.X }` requires `module.rds.X` to be
empty in state. It is **not** — `module.rds.X` already exists (the duplicate).
Terraform rejects a move onto an occupied address, so `moved.tf` would fail the
plan rather than clean it. Hence `state rm` of the stale copy is the correct tool.
