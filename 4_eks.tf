module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.vpc.vpc_id
  # subnet_ids = module.vpc.private_subnets
  subnet_ids = module.vpc.public_subnets # beware that the worker nodes are exposed to the internet

  # enable_irsa = true # use pod identity for eks instead

  eks_managed_node_groups = {
    mini-pool = {

      desired_size = 1
      min_size     = 1
      max_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND" # can be ON_DEMAND / SPOT
    }
  }

  enable_cluster_creator_admin_permissions = true
}
