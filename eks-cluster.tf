# 1. AWS Provider and Terraform version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" 
    }
  }
}

# 2. Kubernetes provider configuration
provider "kubernetes" {
    host                   = data.aws_eks_cluster.myapp-cluster.endpoint
    token                  = data.aws_eks_cluster_auth.myapp-cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)
}

# 3. Data sources for the cluster (using v21 outputs)
data "aws_eks_cluster" "myapp-cluster" {
    name       = module.eks.cluster_name 
    depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "myapp-cluster" {
    name       = module.eks.cluster_name
    depends_on = [module.eks]
}

# 4. Outputs
output "cluster_id" {
  value = data.aws_eks_cluster.myapp-cluster.id
}

# 5. EKS Module (v21.x syntax)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0" # Correctly specifies the module version

  # In v21, cluster_name became 'name'
  name = "myapp-eks-cluster"
  
  # In v21, cluster_version became 'kubernetes_version' to avoid conflicts
  kubernetes_version = "1.30"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id
  
  # In v21, cluster_endpoint_public_access became 'endpoint_public_access'
  endpoint_public_access           = true
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
