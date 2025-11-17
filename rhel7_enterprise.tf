# ============================================================================
# Red Hat 7 EC2 Instance Provisioning
# Using Internal Terraform Enterprise Module
# ============================================================================
# Module: localterraform.com/ag/instance/aws
# Purpose: Deploy RHEL 7 EC2 instance with enterprise-grade configuration
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

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Data Sources - Gather Information from Existing Infrastructure
# ============================================================================

# Get available availability zones
data "aws_availability_zones" "available_enterprise" {
  state = "available"
}

# ============================================================================
# Main RHEL 7 Instance Deployment using Terraform Enterprise Module
# ============================================================================
# Using ONLY parameters that exist in RedHatProducts repository

module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Parameters from RedHatProducts repository only
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
  security_group_ids     = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
  availability_zone      = var.enterprise_availability_zone != null ? var.enterprise_availability_zone : data.aws_availability_zones.available_enterprise.names[0]
  instance_name          = var.enterprise_instance_name
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume

  # Resource tagging (from RedHatProducts repository)
  tags = merge(
    var.enterprise_common_tags,
    {
      Name        = var.enterprise_instance_name
      Environment = var.environment
      Project     = var.project_name
      OS          = "RHEL-7"
      ManagedBy   = "terraform-enterprise"
    }
  )
}