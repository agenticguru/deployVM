# ============================================================================
# Red Hat 7 EC2 Instance Provisioning using Internal Terraform Enterprise Module
# ============================================================================
# This configuration provisions Red Hat 7 EC2 instances using the internal
# Terraform Enterprise module at localterraform.com/ag/instance/aws
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
# Local Values for Enterprise Configuration
# ============================================================================

locals {
  # Enterprise deployment tags based on RedHatProducts repository
  enterprise_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Repository  = "deployVM"
  }

  # Instance naming convention
  enterprise_instance_name = "${var.project_name}-${var.environment}-rhel7-enterprise-${formatdate("YYYYMMDD", timestamp())}"
}

# ============================================================================
# Primary Red Hat 7 Enterprise Instance
# ============================================================================
# Provisions a Red Hat 7 EC2 instance using the internal Terraform Enterprise
# module with ONLY existing parameters from RedHatProducts repository

module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Using ONLY parameters that exist in RedHatProducts repository
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = var.enterprise_subnet_id
  security_group_ids     = var.enterprise_security_group_ids
  availability_zone      = var.enterprise_availability_zone
  instance_name          = local.enterprise_instance_name
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume
  
  tags = merge(
    local.enterprise_tags,
    var.enterprise_additional_tags,
    {
      Name = local.enterprise_instance_name
    }
  )
}

# ============================================================================
# High Availability Configuration (Optional)
# ============================================================================
# Deploy secondary instance in different availability zone for HA
# Using ONLY parameters from RedHatProducts repository

module "rhel7_enterprise_instance_ha" {
  count = var.enable_ha_deployment ? 1 : 0

  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Using ONLY parameters that exist in RedHatProducts repository
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = var.enterprise_subnet_id_secondary
  security_group_ids     = var.enterprise_security_group_ids
  availability_zone      = var.enterprise_availability_zone_secondary
  instance_name          = "${local.enterprise_instance_name}-ha"
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume
  
  tags = merge(
    local.enterprise_tags,
    var.enterprise_additional_tags,
    {
      Name = "${local.enterprise_instance_name}-ha"
      Role = "secondary"
    }
  )
}

# ============================================================================
# Outputs for Enterprise Deployment
# ============================================================================

output "rhel7_enterprise_primary" {
  description = "Primary RHEL 7 enterprise instance details"  
  value = {
    instance_id       = module.rhel7_enterprise_instance.instance_id
    instance_name     = local.enterprise_instance_name
    instance_type     = var.enterprise_instance_type
    availability_zone = var.enterprise_availability_zone
    subnet_id         = var.enterprise_subnet_id
  }
  sensitive = false
}

output "rhel7_enterprise_ha" {
  description = "High availability RHEL 7 instance details (if enabled)"
  value = var.enable_ha_deployment ? {
    instance_id       = module.rhel7_enterprise_instance_ha[0].instance_id
    instance_name     = "${local.enterprise_instance_name}-ha"
    availability_zone = var.enterprise_availability_zone_secondary
    subnet_id         = var.enterprise_subnet_id_secondary
  } : null
  sensitive = false
}

output "rhel7_enterprise_deployment_summary" {
  description = "Complete deployment summary"
  value = {
    module_source     = "localterraform.com/ag/instance/aws"
    instance_count    = var.enable_ha_deployment ? 2 : 1
    instance_type     = var.enterprise_instance_type
    encryption        = var.enterprise_encrypt_root_volume
    high_availability = var.enable_ha_deployment
    environment       = var.environment
    project           = var.project_name
  }
}
