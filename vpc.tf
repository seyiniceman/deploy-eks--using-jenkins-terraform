############################################
# Variables
############################################
variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}

############################################
# Availability Zones (Filtered)
############################################
data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# VPC Module
############################################
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.14"

  name = "myapp-vpc"
  cidr = var.vpc_cidr_block

  # Ensure AZ count matches subnet count
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    length(var.private_subnet_cidr_blocks)
  )

  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  ############################################
  # Networking
  ############################################
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  ############################################
  # Tags for EKS (VERY IMPORTANT)
  ############################################
  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}
