provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "ex-${basename(path.cwd)}"
  region = "eu-west-2" # VPC and IPAM region

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# VPC Module with IPAM Pool for Subnet Planning
################################################################################

# This example demonstrates the native Terraform resource approach for IPAM:
# 1. VPC-scoped IPAM pool using aws_vpc_ipam_pool with source_resource block
# 2. IPAM-allocated subnets using per-type netmask length variables
# 3. RAM sharing for cross-account access using native aws_ram_* resources
#
# By using the per-subnet-type IPAM netmask length variables, subnets get all
# associated resources (route tables, NACLs, NAT routes, etc.) automatically.

module "vpc" {
  source = "../.."

  name = local.name

  # Create VPC using IPAM pool allocation
  use_ipam_pool       = true
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.top_level.id
  ipv4_netmask_length = 16

  azs = local.azs

  # IPAM-allocated subnets - just specify netmask lengths per type.
  # The number of entries controls how many subnets are created (mapped to AZs).
  # CIDRs are automatically allocated from the internal VPC IPAM pool.
  private_subnet_ipam_netmask_lengths = [24, 24, 24] # 3 private /24 subnets
  public_subnet_ipam_netmask_lengths  = [24, 24, 24] # 3 public /24 subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false

  # Enable VPC IPAM Pool for subnet planning (VPC-specific pool)
  create_vpc_ipam_pool = true
  vpc_ipam_scope_id    = aws_vpc_ipam.this.private_default_scope_id
  vpc_ipam_pool_locale = local.region

  # Source pool to allocate from (the top-level IPAM pool)
  vpc_ipam_source_pool_id = aws_vpc_ipam_pool.top_level.id

  # Configure allocation constraints for subnets
  vpc_ipam_pool_allocation_default_netmask_length = 24
  vpc_ipam_pool_allocation_min_netmask_length     = 24
  vpc_ipam_pool_allocation_max_netmask_length     = 20

  # Enable RAM sharing for cross-account access
  vpc_ipam_pool_ram_share_enabled    = true
  vpc_ipam_pool_ram_share_principals = var.ram_share_principals

  tags = local.tags

  depends_on = [
    aws_vpc_ipam_pool_cidr.top_level
  ]
}

################################################################################
# Supporting IPAM Resources
################################################################################

# Top-level IPAM (created in same region as VPC)
# This is the organization-wide or account-wide IPAM instance
resource "aws_vpc_ipam" "this" {
  description = "IPAM for ${local.name}"

  operating_regions {
    region_name = local.region
  }

  tags = local.tags
}

# Top-level IPAM Pool (organization-wide or account-wide)
# Created in same region with locale set to where it operates
# This pool serves as the source for VPC-scoped IPAM pools
resource "aws_vpc_ipam_pool" "top_level" {
  description                       = "Top-level IPv4 pool"
  address_family                    = "ipv4"
  ipam_scope_id                     = aws_vpc_ipam.this.private_default_scope_id
  locale                            = local.region # Where the pool operates (VPC region)
  allocation_default_netmask_length = 16

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-top-level"
    }
  )
}

# Provision CIDR to top-level pool
# This makes the CIDR range available for allocation to VPC-scoped pools
resource "aws_vpc_ipam_pool_cidr" "top_level" {
  ipam_pool_id = aws_vpc_ipam_pool.top_level.id
  cidr         = "10.0.0.0/8"
}
