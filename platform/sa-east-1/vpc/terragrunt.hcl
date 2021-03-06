include {
  path = find_in_parent_folders("")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.64.0"
}

locals {
  aws_region = "sa-east-1"
  aws_account_id = "034506438324"
}

generate "backend" {
  path      = "overwrite_backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "s3" {}
    }
  EOF
}

inputs = {

  tags = {
      "kubernetes.io/cluster/cluster-default" = "shared"
    }

  name = "vpc-eks-default"

  cidr = "10.0.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]
  private_subnet_ipv6_prefixes    = [3, 4, 5]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/cluster-default" = "shared"
    "kubernetes.io/role/elb"                             = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/cluster-default" = "shared"
    "kubernetes.io/role/internal-elb"                    = "1"
  }
}