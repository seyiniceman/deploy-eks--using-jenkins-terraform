############################################
# 1. Terraform & AWS Provider
############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

############################################
# 2. EKS Module
############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "myapp-eks-cluster"
  kubernetes_version = "1.30"

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      # Use t3.small as requested (t2.small is often too small for EKS)
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 3
      key_name       = "sf_key"
    }
  }
  # REMOVED depends_on = [module.myapp-vpc] to fix "Invalid count argument"
}

############################################
# 3. Kubernetes Provider (Direct from Module)
############################################
# IMPORTANT: In v21, use module outputs directly to avoid "Data Source" chicken-and-egg errors
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

############################################
# 4. Outputs
############################################
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
