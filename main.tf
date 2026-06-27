# ==============================================================================
# AI-Travel-Planner — Root Terraform Configuration
# Region: us-east-1 | Environment: prod
# ==============================================================================

module "secrets" {
  source = "./modules/secrets"

  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  aws_region         = var.aws_region
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  account_id   = local.account_id
  github_org   = var.github_org
  github_repo  = var.github_repo
  github_repos = var.github_repos
  tags         = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  repositories = var.ecr_repositories
  kms_key_arn  = module.secrets.kms_key_arn
  tags         = local.common_tags

  depends_on = [module.secrets]
}

module "eks" {
  source = "./modules/eks"

  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.vpc.eks_cluster_security_group_id
  node_group_min_size       = var.node_group_min_size
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_instance_types       = var.node_instance_types
  node_disk_size            = var.node_disk_size
  cluster_iam_role_arn      = module.iam.cluster_iam_role_arn
  node_iam_role_arn         = module.iam.node_iam_role_arn
  kms_key_arn               = module.secrets.kms_key_arn
  log_retention_days        = var.log_retention_days
  tags                      = local.common_tags

  depends_on = [module.vpc, module.iam, module.secrets]
}

module "rds" {
  source = "./modules/rds"

  project_name                  = var.project_name
  environment                   = var.environment
  instance_class                = var.db_instance_class
  allocated_storage             = var.db_allocated_storage
  max_allocated_storage         = var.db_max_allocated_storage
  db_name                       = var.db_name
  db_username                   = var.db_username
  db_password_secret_arn        = module.secrets.rds_password_secret_arn
  database_subnet_ids           = module.vpc.database_subnet_ids
  vpc_id                        = module.vpc.vpc_id
  eks_security_group_id         = module.vpc.eks_cluster_security_group_id
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  kms_key_arn                   = module.secrets.kms_key_arn
  backup_retention_days         = var.db_backup_retention_days
  multi_az                      = var.enable_rds_multi_az
  tags                          = local.common_tags

  depends_on = [module.vpc, module.secrets, module.eks]
}

module "alb" {
  count  = var.enable_legacy_alb ? 1 : 0
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_security_group = module.vpc.alb_security_group_id
  certificate_domain = var.acm_certificate_domain
  kms_key_arn        = module.secrets.kms_key_arn
  account_id         = local.account_id
  region             = local.region
  tags               = local.common_tags

  depends_on = [module.vpc, module.secrets]
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  log_retention_days      = var.log_retention_days
  kms_key_arn             = module.secrets.kms_key_arn
  sns_topic_email         = var.alert_email
  enable_rds_alarms       = true
  enable_alb_alarms       = var.enable_legacy_alb
  rds_instance_id         = module.rds.db_instance_id
  alb_arn_suffix          = var.enable_legacy_alb ? module.alb[0].alb_arn_suffix : ""
  target_group_arn_suffix = var.enable_legacy_alb ? module.alb[0].target_group_arn_suffix : ""
  tags                    = local.common_tags

  depends_on = [module.secrets, module.rds]
}

module "governance" {
  source = "./modules/governance"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  account_id               = local.account_id
  kms_key_arn              = module.secrets.kms_key_arn
  monitoring_sns_topic_arn = module.monitoring.sns_topic_arn
  tags                     = local.common_tags

  depends_on = [module.secrets, module.monitoring]
}

module "finops" {
  source = "./modules/finops"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  dynamodb_table_name   = var.finops_dynamodb_table_name
  kms_key_arn           = module.secrets.kms_key_arn
  lambda_function_name  = var.finops_lambda_function_name
  eventbridge_rule_name = var.finops_eventbridge_rule_name
  schedule_expression   = var.finops_schedule_expression
  sender_email          = var.finops_sender_email
  tags                  = local.common_tags

  depends_on = [module.secrets]
}

module "irsa" {
  source = "./modules/irsa"

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  account_id        = local.account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = replace(module.eks.oidc_issuer_url, "https://", "")
  namespace         = var.k8s_namespace
  sqs_queue_arn     = module.sqs.ai_jobs_queue_arn
  jobs_table_arn    = module.sqs.ai_jobs_table_arn
  enable_async_jobs = true
  tags              = local.common_tags

  depends_on = [module.eks, module.sqs]
}

module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.secrets.kms_key_arn
  tags         = local.common_tags

  depends_on = [module.secrets]
}

module "karpenter" {
  source = "./modules/karpenter"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = var.cluster_name
  aws_region        = var.aws_region
  account_id        = local.account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = replace(module.eks.oidc_issuer_url, "https://", "")
  tags              = local.common_tags

  depends_on = [module.eks]
}

module "cognito" {
  source = "./modules/cognito"

  project_name    = var.project_name
  environment     = var.environment
  domain_prefix   = var.cognito_domain_prefix
  callback_urls   = var.cognito_callback_urls
  logout_urls     = var.cognito_logout_urls
  frontend_domain = var.frontend_domain
  tags            = local.common_tags
}

# frontend_hosting (S3 + CloudFront) removed: the frontend is now served from the
# in-cluster pod via the KGateway NLB (HTTPRoute on invest-iq.online). The module
# remains under modules/frontend-hosting but is intentionally no longer wired.
