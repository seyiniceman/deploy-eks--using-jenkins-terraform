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
  region = "eu-west-1" # Ireland region (adjust if needed)
}

############################################
# 2. Required Data Sources (FIX FOR YOUR ERROR)
############################################
data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

############################################
# 3. EKS Module (v21.x)
############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "myapp-eks-cluster"
  kubernetes_version = "1.30"

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  # ✅ FIX: explicitly pass these (prevents count error)
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.small"] # 🔥 t2 is deprecated for EKS
      key_name       = "sf_key"
    }
  }

  depends_on = [module.myapp-vpc]
}

############################################
# 4. EKS Data Sources (AFTER CLUSTER CREATION)
############################################
data "aws_eks_cluster" "myapp_cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "myapp_cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

############################################
# 5. Kubernetes Provider
############################################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.myapp_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.myapp_cluster.token
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.myapp_cluster.certificate_authority[0].data
  )
}

############################################
# 6. Outputs
############################################
output "cluster_id" {
  value = data.aws_eks_cluster.myapp_cluster.id
}
