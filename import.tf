# One-time import: absorbs the existing EKS node group into Terraform state.
# The node group was created before this state file tracked it.
# Remove this file after the next successful terraform apply.
import {
  to = module.eks.aws_eks_node_group.workers
  id = "ai-travel-prod:ai-travel-prod-workers"
}
