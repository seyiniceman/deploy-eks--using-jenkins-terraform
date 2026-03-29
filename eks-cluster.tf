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

  # FIX: Grants your IAM user permission to view/manage nodes in the AWS Console
  access_entries = {
    console_access = {
      principal_arn     = "arn:aws:iam::021891594207:user/myownyolk"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:iam::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # FIX: Ensures the new KMS key allows the nodes to talk to the cluster
  create_kms_key                = true
  kms_key_enable_default_policy = true
  kms_key_administrators        = ["arn:aws:iam::021891594207:root"]

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 3
      key_name       = "sf_key"

      # FIX: Ensures the CNI has permission to assign networking to the nodes
      iam_role_additional_policies = {
        AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      }
    }
  }
}

############################################
# 3. Kubernetes Provider
############################################
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
