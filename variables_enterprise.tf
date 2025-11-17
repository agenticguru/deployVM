# ============================================================================
# Variable Definitions for RHEL 7 Enterprise Module Deployment
# ============================================================================
# Based on RedHatProducts repository documentation
# Module: localterraform.com/ag/instance/aws
# ============================================================================

# ============================================================================
# Required Variables
# ============================================================================

variable "enterprise_instance_type" {
  description = "EC2 instance type for the RHEL 7 instance. Choose based on workload: t3.micro (dev), t3.medium (small prod), m5.large (production), c5.large (compute-intensive)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^(t[23]|m[56]|c[56]|r[56]|i3)\\.", var.enterprise_instance_type))
    error_message = "Instance type must be a valid EC2 instance type from t2/t3, m5/m6, c5/c6, r5/r6, or i3 families."
  }
}

variable "enterprise_key_name" {
  description = "Name of the EC2 key pair for SSH access to the RHEL 7 instance. Must exist in the target AWS region."
  type        = string

  validation {
    condition     = length(var.enterprise_key_name) > 0
    error_message = "Key name cannot be empty. Please provide a valid EC2 key pair name."
  }
}

# ============================================================================
# Optional Core Variables
# ============================================================================

variable "enterprise_instance_name" {
  description = "Name tag for the RHEL 7 EC2 instance. Recommended format: {project}-{environment}-{purpose}-rhel7"
  type        = string
  default     = "redhat7-enterprise-instance"
}

# ============================================================================
# Networking Variables
# ============================================================================

variable "enterprise_subnet_id" {
  description = "VPC subnet ID where the instance will be launched. If null, will use the default subnet from main infrastructure."
  type        = string
  default     = null
}

variable "enterprise_security_group_ids" {
  description = "List of security group IDs to attach to the instance. If null, will use the default security group from main infrastructure."
  type        = list(string)
  default     = null
}

variable "enterprise_availability_zone" {
  description = "AWS availability zone for instance placement. If null, will use the first available AZ in the region."
  type        = string
  default     = null
}

variable "enterprise_associate_public_ip" {
  description = "Whether to associate a public IP address with the instance. Set to false for private subnet deployments."
  type        = bool
  default     = true
}

variable "enterprise_private_ip" {
  description = "Private IP address to assign to the instance within the subnet CIDR range. If null, AWS will assign automatically."
  type        = string
  default     = null
}

# ============================================================================
# Storage Configuration Variables
# ============================================================================

variable "enterprise_root_volume_type" {
  description = "Type of root EBS volume. Options: gp2 (general purpose SSD), gp3 (improved gp2), io1 (provisioned IOPS SSD), io2 (improved io1)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.enterprise_root_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "enterprise_root_volume_size" {
  description = "Size of the root volume in GB. Minimum 10 GB for RHEL 7. Recommended: 20GB (dev), 50GB (small apps), 100GB+ (production)"
  type        = number
  default     = 20

  validation {
    condition     = var.enterprise_root_volume_size >= 10 && var.enterprise_root_volume_size <= 1000
    error_message = "Volume size must be between 10 and 1000 GB."
  }
}

variable "enterprise_encrypt_root_volume" {
  description = "Enable encryption for the root EBS volume. Strongly recommended for production workloads."
  type        = bool
  default     = true
}

variable "enterprise_delete_volume_on_termination" {
  description = "Whether to delete the root volume when the instance is terminated."
  type        = bool
  default     = true
}

# ============================================================================
# Advanced Configuration Variables
# ============================================================================

variable "enterprise_user_data" {
  description = "User data script to execute on instance launch. Use for initial configuration, package installation, etc."
  type        = string
  default     = <<-EOF
    #!/bin/bash
    # RHEL 7 Instance Initialization Script
    # Deployed via Terraform Enterprise Module
    
    # Update system packages
    yum update -y
    
    # Install common utilities
    yum install -y wget curl vim git htop
    
    # Configure system logging
    echo "Instance initialized at $(date)" >> /var/log/terraform-deployment.log
    
    # Set hostname
    hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
    
    # Enable automatic security updates
    yum install -y yum-cron
    systemctl enable yum-cron
    systemctl start yum-cron
  EOF
}

variable "enterprise_iam_instance_profile" {
  description = "IAM instance profile name to attach to the instance. Provides AWS API access without embedding credentials."
  type        = string
  default     = null
}

variable "enterprise_enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute intervals instead of 5-minute). Additional charges apply."
  type        = bool
  default     = false
}

variable "enterprise_ebs_optimized" {
  description = "Enable EBS optimization for enhanced storage performance. Recommended for production workloads."
  type        = bool
  default     = true
}

variable "enterprise_disable_api_termination" {
  description = "Protect instance from accidental termination via AWS API/Console. Must be disabled before termination."
  type        = bool
  default     = false
}

variable "enterprise_tenancy" {
  description = "Instance tenancy type. Options: default (shared hardware), dedicated (dedicated hardware), host (dedicated host)"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.enterprise_tenancy)
    error_message = "Tenancy must be one of: default, dedicated, host."
  }
}

# ============================================================================
# Tagging Variables
# ============================================================================

variable "enterprise_common_tags" {
  description = "Common tags to apply to all resources. Should include Environment, Project, Owner, CostCenter, etc."
  type        = map(string)
  default = {
    Terraform   = "true"
    Module      = "terraform-enterprise"
    Repository  = "deployVM"
    OS          = "RHEL-7"
  }
}

variable "enterprise_volume_tags" {
  description = "Additional tags to apply specifically to EBS volumes."
  type        = map(string)
  default     = {}
}

# ============================================================================
# Instance Type Selection Guide (Documentation)
# ============================================================================
# 
# Development/Testing:
#   - t3.micro:  2 vCPU, 1 GB RAM  (~$8/month)
#   - t3.small:  2 vCPU, 2 GB RAM  (~$15/month)
#
# Small Production:
#   - t3.medium: 2 vCPU, 4 GB RAM  (~$30/month)
#   - m5.large:  2 vCPU, 8 GB RAM  (~$70/month)
#
# Production:
#   - m5.xlarge: 4 vCPU, 16 GB RAM (~$140/month)
#   - m5.2xlarge: 8 vCPU, 32 GB RAM (~$280/month)
#
# Compute-Intensive:
#   - c5.large:  2 vCPU, 4 GB RAM  (~$62/month)
#   - c5.xlarge: 4 vCPU, 8 GB RAM  (~$124/month)
#
# Memory-Optimized:
#   - r5.large:  2 vCPU, 16 GB RAM (~$91/month)
#   - r5.xlarge: 4 vCPU, 32 GB RAM (~$182/month)
#
# High I/O:
#   - i3.large:  2 vCPU, 15.25 GB RAM, 475 GB NVMe SSD (~$113/month)
#   - i3.xlarge: 4 vCPU, 30.5 GB RAM, 950 GB NVMe SSD (~$226/month)
#
# ============================================================================

# ============================================================================
# Storage Configuration Guide (Documentation)
# ============================================================================
#
# Volume Types:
#   - gp2: General Purpose SSD, 3 IOPS/GB (max 16,000), baseline performance
#   - gp3: General Purpose SSD, 3,000 IOPS baseline, better price/performance
#   - io1: Provisioned IOPS SSD, up to 64,000 IOPS, high-performance databases
#   - io2: Provisioned IOPS SSD, up to 64,000 IOPS, mission-critical workloads
#
# Recommended Sizes:
#   - 10-20 GB:   Minimal OS-only installations
#   - 20-50 GB:   Development and testing
#   - 50-100 GB:  Small production applications
#   - 100-500 GB: Standard production deployments
#   - 500+ GB:    Large applications, databases, log storage
#
# ============================================================================
