# ============================================================================
# Enterprise Module Variables for Red Hat 7 EC2 Deployment
# ============================================================================
# Variables specific to the internal Terraform Enterprise module
# at localterraform.com/ag/instance/aws
#
# Using ONLY parameters that exist in RedHatProducts repository
# ============================================================================

# ============================================================================
# Core Instance Configuration (from RedHatProducts repository)
# ============================================================================

variable "enterprise_instance_type" {
  description = "EC2 instance type for the Red Hat 7 enterprise deployment"
  type        = string
  default     = "t3.micro"
}

variable "enterprise_key_name" {
  description = "AWS EC2 Key Pair name for SSH access to Red Hat 7 instances"
  type        = string
}

# ============================================================================
# Network Configuration (from RedHatProducts repository)
# ============================================================================

variable "enterprise_subnet_id" {
  description = "VPC subnet ID where the primary Red Hat 7 instance will be launched"
  type        = string
}

variable "enterprise_subnet_id_secondary" {
  description = "VPC subnet ID for secondary instance in HA deployment (different AZ recommended)"
  type        = string
  default     = null
}

variable "enterprise_security_group_ids" {
  description = "List of security group IDs to attach to Red Hat 7 instances"
  type        = list(string)
}

variable "enterprise_availability_zone" {
  description = "Availability zone for the primary Red Hat 7 instance"
  type        = string
}

variable "enterprise_availability_zone_secondary" {
  description = "Availability zone for the secondary Red Hat 7 instance in HA deployment"
  type        = string
  default     = null
}

# ============================================================================
# Instance Naming (from RedHatProducts repository)
# ============================================================================

variable "instance_name" {
  description = "Name tag for the instance (computed from other variables if not provided)"
  type        = string
  default     = "redhat7-enterprise-instance"
}

# ============================================================================
# Storage Configuration (from RedHatProducts repository)
# ============================================================================

variable "enterprise_root_volume_type" {
  description = "EBS volume type for the root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "enterprise_root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "enterprise_encrypt_root_volume" {
  description = "Enable encryption for the root EBS volume"
  type        = bool
  default     = true
}

# ============================================================================
# Tagging (from RedHatProducts repository)
# ============================================================================

variable "enterprise_additional_tags" {
  description = "Additional tags to apply to Red Hat 7 enterprise resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# High Availability Configuration
# ============================================================================

variable "enable_ha_deployment" {
  description = "Enable high availability deployment with secondary instance in different AZ"
  type        = bool
  default     = false
}
