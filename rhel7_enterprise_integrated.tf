# ============================================================================
# RHEL 7 Enterprise Module - Integrated with Existing Infrastructure
# ============================================================================
# This file demonstrates how to use the Terraform Enterprise module
# alongside the existing deployVM infrastructure (VPC, subnets, security groups)
#
# Using ONLY parameters from RedHatProducts repository:
# - instance_type
# - key_name
# - subnet_id
# - security_group_ids
# - availability_zone
# - instance_name
# - root_volume_type
# - root_volume_size
# - encrypt_root_volume
# - tags
# ============================================================================

# ============================================================================
# Local Values for Configuration Management
# ============================================================================

locals {
  # Common tags applied to all resources (from RedHatProducts repository)
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Repository  = "deployVM"
  }

  # Instance naming convention
  instance_name = "${var.project_name}-${var.environment}-rhel7-enterprise"
  
  # Use enterprise variables if provided, otherwise fall back to existing infrastructure
  subnet_id = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
  security_groups = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
}

# ============================================================================
# Terraform Enterprise Module Deployment (Primary Instance)
# ============================================================================
# Using ONLY parameters that exist in RedHatProducts repository

module "rhel7_primary_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Parameters from RedHatProducts repository only
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = local.subnet_id
  security_group_ids     = local.security_groups
  availability_zone      = var.enterprise_availability_zone
  instance_name          = local.instance_name
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume

  # Resource tagging (from RedHatProducts repository)
  tags = merge(local.common_tags, {
    Name = local.instance_name
    Role = "primary"
  })
}

# ============================================================================
# Secondary Instance for High Availability (Optional)
# ============================================================================
# Using ONLY parameters that exist in RedHatProducts repository

module "rhel7_secondary_instance" {
  count = var.enable_secondary_instance ? 1 : 0
  
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Parameters from RedHatProducts repository only
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = local.subnet_id
  security_group_ids     = local.security_groups
  availability_zone      = var.enterprise_availability_zone_secondary != null ? var.enterprise_availability_zone_secondary : data.aws_availability_zones.available.names[1]
  instance_name          = "${local.instance_name}-secondary"
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume

  # Resource tagging (from RedHatProducts repository)
  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-secondary"
    Role = "secondary"
  })
}

# ============================================================================
# Additional Variables for Integrated Deployment
# ============================================================================

variable "enable_secondary_instance" {
  description = "Enable deployment of a secondary RHEL 7 instance for high availability"
  type        = bool
  default     = false
}

# ============================================================================
# Outputs for Integrated Deployment
# ============================================================================

output "rhel7_primary_instance" {
  description = "Primary RHEL 7 instance details"
  value = {
    instance_id = module.rhel7_primary_instance.instance_id
    instance_name = local.instance_name
  }
}

output "rhel7_secondary_instance" {
  description = "Secondary RHEL 7 instance details (if enabled)"
  value = var.enable_secondary_instance ? {
    instance_id = module.rhel7_secondary_instance[0].instance_id
    instance_name = "${local.instance_name}-secondary"
  } : null
}

output "integrated_deployment_summary" {
  description = "Summary of the integrated RHEL 7 deployment"
  value = {
    primary_instance  = module.rhel7_primary_instance.instance_id
    secondary_enabled = var.enable_secondary_instance
    vpc_id            = aws_vpc.main.id
    subnet_id         = aws_subnet.public.id
    security_group_id = aws_security_group.redhat_sg.id
  }
}
