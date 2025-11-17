# ============================================================================
# Output Definitions for RHEL 7 Enterprise Module Deployment
# ============================================================================
# Based on RedHatProducts repository documentation
# Module: localterraform.com/ag/instance/aws
#
# Outputs related to parameters that exist in RedHatProducts repository
# ============================================================================

# ============================================================================
# Instance Information Outputs
# ============================================================================

output "enterprise_instance_id" {
  description = "The unique identifier (ID) of the RHEL 7 EC2 instance"
  value       = module.rhel7_enterprise_instance.instance_id
}

# ============================================================================
# Instance Configuration Outputs (from RedHatProducts parameters)
# ============================================================================

output "enterprise_instance_type" {
  description = "EC2 instance type used"
  value       = var.enterprise_instance_type
}

output "enterprise_instance_name" {
  description = "Name tag of the instance"
  value       = var.enterprise_instance_name
}

output "enterprise_key_name" {
  description = "The key pair name used for SSH access"
  value       = var.enterprise_key_name
}

# ============================================================================
# Network Configuration Outputs (from RedHatProducts parameters)
# ============================================================================

output "enterprise_subnet_id" {
  description = "The subnet ID where the instance is deployed"
  value       = var.enterprise_subnet_id
}

output "enterprise_security_groups" {
  description = "List of security group IDs attached to the instance"
  value       = var.enterprise_security_group_ids
}

output "enterprise_availability_zone" {
  description = "The availability zone where the RHEL 7 instance is running"
  value       = var.enterprise_availability_zone
}

# ============================================================================
# Storage Configuration Outputs (from RedHatProducts parameters)
# ============================================================================

output "enterprise_root_volume_type" {
  description = "Type of the root EBS volume"
  value       = var.enterprise_root_volume_type
}

output "enterprise_root_volume_size" {
  description = "Size of the root volume in GB"
  value       = var.enterprise_root_volume_size
}

output "enterprise_root_volume_encrypted" {
  description = "Whether the root volume is encrypted"
  value       = var.enterprise_encrypt_root_volume
}

# ============================================================================
# Tagging Outputs (from RedHatProducts parameters)
# ============================================================================

output "enterprise_instance_tags" {
  description = "Tags applied to the RHEL 7 instance"
  value = merge(
    var.enterprise_common_tags,
    {
      Name        = var.enterprise_instance_name
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# ============================================================================
# Configuration Summary Output
# ============================================================================

output "enterprise_deployment_summary" {
  description = "Comprehensive summary of the RHEL 7 enterprise deployment"
  value = {
    # Instance details
    instance_id       = module.rhel7_enterprise_instance.instance_id
    instance_type     = var.enterprise_instance_type
    instance_name     = var.enterprise_instance_name
    
    # Network details
    subnet_id         = var.enterprise_subnet_id
    availability_zone = var.enterprise_availability_zone
    security_groups   = var.enterprise_security_group_ids
    
    # Storage details
    volume_type       = var.enterprise_root_volume_type
    volume_size       = "${var.enterprise_root_volume_size} GB"
    encrypted         = var.enterprise_encrypt_root_volume
    
    # Security details
    key_name          = var.enterprise_key_name
    
    # Deployment details
    deployment_type   = "Terraform Enterprise Module"
    module_source     = "localterraform.com/ag/instance/aws"
    managed_by        = "terraform-enterprise"
  }
}