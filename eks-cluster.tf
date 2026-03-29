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
# 2. EKS Module (v21.x)
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
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.small"]
      key_name       = "sf_key"
    }
  }

  depends_on = [module.myapp-vpc]
}

############################################
# 3. EKS Data Sources
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
# 4. Kubernetes Provider
############################################
provider "kubernetes" {
  host  = data.aws_eks_cluster.myapp_cluster.endpoint
  token = data.aws_eks_cluster_auth.myapp_cluster.token
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.myapp_cluster.certificate_authority[0].data
  )
}

############################################
# 5. Outputs
############################################
output "cluster_id" {
  value = data.aws_eks_cluster.myapp_cluster.id
}
