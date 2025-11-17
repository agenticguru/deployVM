# ============================================================================
# Red Hat 7 EC2 Instance Provisioning
# Using Internal Terraform Enterprise Module
# ============================================================================
# Module: localterraform.com/ag/instance/aws
# Purpose: Deploy RHEL 7 EC2 instance with enterprise-grade configuration
# Documentation: Based on RedHatProducts repository parameters
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

# Get latest Red Hat 7 AMI
data "aws_ami" "rhel7_enterprise" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat AWS Account

  filter {
    name   = "name"
    values = ["RHEL-7.*-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Get available availability zones
data "aws_availability_zones" "available_enterprise" {
  state = "available"
}

# ============================================================================
# Main RHEL 7 Instance Deployment using Terraform Enterprise Module
# ============================================================================

module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # ----------------------------------------------------------------------------
  # Required Parameters
  # ----------------------------------------------------------------------------
  
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name

  # ----------------------------------------------------------------------------
  # Optional Core Parameters
  # ----------------------------------------------------------------------------
  
  instance_name = var.enterprise_instance_name

  # ----------------------------------------------------------------------------
  # Networking Parameters (if supported by enterprise module)
  # ----------------------------------------------------------------------------
  
  subnet_id              = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
  security_group_ids     = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
  availability_zone      = var.enterprise_availability_zone != null ? var.enterprise_availability_zone : data.aws_availability_zones.available_enterprise.names[0]
  associate_public_ip    = var.enterprise_associate_public_ip

  # ----------------------------------------------------------------------------
  # Storage Configuration
  # ----------------------------------------------------------------------------
  
  root_volume_type    = var.enterprise_root_volume_type
  root_volume_size    = var.enterprise_root_volume_size
  encrypt_root_volume = var.enterprise_encrypt_root_volume

  # ----------------------------------------------------------------------------
  # Advanced Configuration
  # ----------------------------------------------------------------------------
  
  user_data              = var.enterprise_user_data
  iam_instance_profile   = var.enterprise_iam_instance_profile
  monitoring             = var.enterprise_enable_monitoring
  ebs_optimized          = var.enterprise_ebs_optimized
  disable_api_termination = var.enterprise_disable_api_termination

  # ----------------------------------------------------------------------------
  # Resource Tagging
  # ----------------------------------------------------------------------------
  
  tags = merge(
    var.enterprise_common_tags,
    {
      Name           = var.enterprise_instance_name
      Environment    = var.environment
      Project        = var.project_name
      OS             = "RHEL-7"
      ManagedBy      = "terraform-enterprise"
      DeploymentType = "enterprise-module"
      AMI            = data.aws_ami.rhel7_enterprise.id
      AMIName        = data.aws_ami.rhel7_enterprise.name
    }
  )
}

# ============================================================================
# Additional Resources (if using existing infrastructure)
# ============================================================================

# Note: The following resources are conditionally created if not provided
# via variables. This allows flexibility in using existing or new infrastructure.

# Create VPC if needed (reusing existing from main.tf if available)
# resource "aws_vpc" "main" { ... }

# Create subnet if needed (reusing existing from main.tf if available)
# resource "aws_subnet" "public" { ... }

# Create security group if needed (reusing existing from main.tf if available)
# resource "aws_security_group" "redhat_sg" { ... }
