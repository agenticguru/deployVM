# ============================================================================
# Variable Definitions for RHEL 7 Enterprise Module Deployment
# ============================================================================
# Based on RedHatProducts repository documentation
# Module: localterraform.com/ag/instance/aws
#
# Using ONLY parameters that exist in RedHatProducts repository:
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
# Required Variables (from RedHatProducts repository)
# ============================================================================

variable "enterprise_instance_type" {
  description = "EC2 instance type for the RHEL 7 instance"
  type        = string
  default     = "t3.micro"
}

variable "enterprise_key_name" {
  description = "Name of the EC2 key pair for SSH access to the RHEL 7 instance"
  type        = string
}

# ============================================================================
# Network Configuration Variables (from RedHatProducts repository)
# ============================================================================

variable "enterprise_subnet_id" {
  description = "VPC subnet ID where the instance will be launched"
  type        = string
  default     = null
}

variable "enterprise_security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = null
}

variable "enterprise_availability_zone" {
  description = "AWS availability zone for instance placement"
  type        = string
  default     = null
}

variable "enterprise_availability_zone_secondary" {
  description = "AWS availability zone for secondary instance in HA deployment"
  type        = string
  default     = null
}  

# ============================================================================
# Instance Naming Variables (from RedHatProducts repository)
# ============================================================================

variable "enterprise_instance_name" {
  description = "Name tag for the RHEL 7 EC2 instance"
  type        = string
  default     = "redhat7-enterprise-instance"
}

# ============================================================================
# Storage Configuration Variables (from RedHatProducts repository)
# ============================================================================

variable "enterprise_root_volume_type" {
  description = "Type of root EBS volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "enterprise_root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "enterprise_encrypt_root_volume" {
  description = "Enable encryption for the root EBS volume"
  type        = bool
  default     = true
}

# ============================================================================
# Tagging Variables (from RedHatProducts repository)
# ============================================================================

variable "enterprise_common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform  = "true"
    Module     = "terraform-enterprise"
    Repository = "deployVM"
    OS         = "RHEL-7"
  }
}