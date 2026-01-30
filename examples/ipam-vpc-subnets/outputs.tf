################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC (allocated from top-level IPAM pool)"
  value       = module.vpc.vpc_cidr_block
}

################################################################################
# VPC IPAM Pool Outputs
################################################################################

# The VPC IPAM pool is created using the native aws_vpc_ipam_pool resource
# with a source_resource block that scopes it to the VPC

output "vpc_ipam_pool_id" {
  description = "The ID of the VPC-scoped IPAM pool for subnet allocation (from aws_vpc_ipam_pool resource)"
  value       = module.vpc.vpc_ipam_pool_id
}

output "vpc_ipam_pool_arn" {
  description = "The ARN of the VPC-scoped IPAM pool (from aws_vpc_ipam_pool resource)"
  value       = module.vpc.vpc_ipam_pool_arn
}

output "vpc_ipam_pool_cidr" {
  description = "The CIDR provisioned to the VPC IPAM pool (from aws_vpc_ipam_pool_cidr resource)"
  value       = module.vpc.vpc_ipam_pool_cidr
}

################################################################################
# RAM Share Outputs
################################################################################

# RAM sharing is managed using native aws_ram_resource_share,
# aws_ram_resource_association, and aws_ram_principal_association resources

output "vpc_ipam_pool_ram_share_id" {
  description = "The ID of the RAM resource share (from aws_ram_resource_share resource)"
  value       = module.vpc.vpc_ipam_pool_ram_share_id
}

output "vpc_ipam_pool_ram_share_arn" {
  description = "The ARN of the RAM resource share (from aws_ram_resource_share resource)"
  value       = module.vpc.vpc_ipam_pool_ram_share_arn
}

################################################################################
# Subnet Outputs (IPAM-allocated via standard subnet resources)
################################################################################

# Subnets are created using the standard aws_subnet.private and aws_subnet.public
# resources with ipv4_ipam_pool_id parameter, so they get all associated resources
# (route tables, NACLs, NAT routes, etc.) automatically.

output "private_subnets" {
  description = "List of private subnet IDs (IPAM-allocated)"
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of private subnet CIDR blocks (IPAM-allocated)"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of public subnet IDs (IPAM-allocated)"
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of public subnet CIDR blocks (IPAM-allocated)"
  value       = module.vpc.public_subnets_cidr_blocks
}

################################################################################
# Top-level IPAM Outputs
################################################################################

output "top_level_ipam_id" {
  description = "The ID of the top-level IPAM instance"
  value       = aws_vpc_ipam.this.id
}

output "top_level_ipam_pool_id" {
  description = "The ID of the top-level IPAM pool (source pool for VPC-scoped pools)"
  value       = aws_vpc_ipam_pool.top_level.id
}
