include {
  path = find_in_parent_folders("")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v13.2.1"
}

locals {
  aws_region = "sa-east-1"
  aws_account_id = "034506438324"
  cluster_name   = "cluster-default"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
      load_config_file       = false
    }
    data "aws_eks_cluster" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
  EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "s3" {}
    }
  EOF
}

inputs = {

  aws = {
    "region" = local.aws_region
  }


  cluster_name                         = local.cluster_name
  subnets                              = dependency.vpc.outputs.private_subnets
  vpc_id                               = dependency.vpc.outputs.vpc_id
  write_kubeconfig                     = true
  enable_irsa                          = true
  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    local.cluster_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  cluster_version           = "1.18"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    "default-${local.aws_region}a" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[0]]
      disk_size        = 50
    }

    "default-${local.aws_region}b" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[1]]
      disk_size        = 50
    }

    "default-${local.aws_region}c" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[2]]
      disk_size        = 50
    }
  }
}