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

# Variable to allow local use with "Seyi" but empty for Jenkins
variable "aws_profile" {
  type    = string
  default = "" 
}

provider "aws" {
  region  = "eu-west-1"
  profile = var.aws_profile 
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

  endpoint_public_access = true
  
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  ############################################
  # FIX: Using 'addons' as requested
  ############################################
  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true 
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  create_kms_key                = true
  kms_key_enable_default_policy = true
  kms_key_administrators        = ["arn:aws:iam::021891594207:root"]
  
  create_cloudwatch_log_group = false

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
    # FIX: Removed --profile Seyi so Jenkins credentials work
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

############################################
# 4. Outputs
############################################
output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
