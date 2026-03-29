# 1. ADD THIS BLOCK FIRST: Tells Terraform to use the newer AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" 
    }
  }
}

provider "kubernetes" {
    host                   = data.aws_eks_cluster.myapp-cluster.endpoint
    token                  = data.aws_eks_cluster_auth.myapp-cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)
}

data "aws_eks_cluster" "myapp-cluster" {
    name       = module.eks.cluster_name
    depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "myapp-cluster" {
    name       = module.eks.cluster_name
    depends_on = [module.eks]
}

output "cluster_id" {
  value = data.aws_eks_cluster.myapp-cluster.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  # Fixes compatibility with AWS Provider v6
  version = "~> 21.0" 

  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.30"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id
  
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t2.small"]
      key_name       = "sf_key"
    }
  }
  
  depends_on = [module.myapp-vpc]
}
