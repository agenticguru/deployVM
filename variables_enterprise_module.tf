# ============================================================================
# Enterprise Module Variables for Red Hat 7 EC2 Deployment
# ============================================================================
# Variables specific to the internal Terraform Enterprise module
# at localterraform.com/ag/instance/aws
# ============================================================================

# ============================================================================
# Core Enterprise Instance Configuration
# ============================================================================

variable "enterprise_instance_type" {
  description = "EC2 instance type for the Red Hat 7 enterprise deployment"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = can(regex("^[a-z][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.enterprise_instance_type))
    error_message = "Instance type must be a valid EC2 instance type (e.g., t3.micro, m5.large)."
  }
}

variable "enterprise_key_name" {
  description = "AWS EC2 Key Pair name for SSH access to Red Hat 7 instances"
  type        = string
  
  validation {
    condition     = length(var.enterprise_key_name) > 0
    error_message = "Key name must not be empty."
  }
}

# ============================================================================
# Network Configuration Variables
# ============================================================================

variable "enterprise_subnet_id" {
  description = "VPC subnet ID where the primary Red Hat 7 instance will be launched (if not provided, uses existing infrastructure)"
  type        = string
  default     = null
}

variable "enterprise_subnet_id_secondary" {
  description = "VPC subnet ID for secondary instance in HA deployment (different AZ recommended)"
  type        = string
  default     = null
}

variable "enterprise_security_group_ids" {
  description = "List of security group IDs to attach to Red Hat 7 instances (if not provided, uses existing security group)"
  type        = list(string)
  default     = null
}

variable "enterprise_availability_zone" {
  description = "Specific availability zone for the primary Red Hat 7 instance (if not specified, uses first available AZ)"
  type        = string
  default     = null
}

variable "enterprise_associate_public_ip" {
  description = "Whether to associate a public IP address with the Red Hat 7 instances"
  type        = bool
  default     = true
}

# ============================================================================
# Storage Configuration Variables
# ============================================================================

variable "enterprise_root_volume_type" {
  description = "EBS volume type for the root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.enterprise_root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "enterprise_root_volume_size" {
  description = "Size of the root EBS volume in GB (minimum 10 GB for RHEL 7)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.enterprise_root_volume_size >= 10
    error_message = "Root volume size must be at least 10 GB for Red Hat Enterprise Linux 7."
  }
}

variable "enterprise_encrypt_root_volume" {
  description = "Enable encryption for the root EBS volume (recommended for enterprise deployments)"
  type        = bool
  default     = true
}

variable "enterprise_kms_key_id" {
  description = "KMS key ID for EBS volume encryption (if not provided, uses AWS managed key)"
  type        = string
  default     = null
}

variable "enterprise_additional_volumes" {
  description = "Additional EBS volumes to attach to the instance"
  type = list(object({
    device_name           = string
    volume_type          = string
    volume_size          = number
    encrypted            = bool
    kms_key_id           = optional(string)
    delete_on_termination = bool
  }))
  default = []
}

# ============================================================================
# Advanced Instance Configuration
# ============================================================================

variable "enterprise_user_data" {
  description = "User data script for Red Hat 7 instance bootstrapping (if not provided, uses default bootstrap script)"
  type        = string
  default     = null
}

variable "enterprise_user_data_replace_on_change" {
  description = "Replace instance when user data changes"
  type        = bool
  default     = false
}

variable "enterprise_iam_instance_profile" {
  description = "IAM instance profile name to attach to Red Hat 7 instances for AWS service permissions"
  type        = string
  default     = null
}

variable "enterprise_enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring for Red Hat 7 instances"
  type        = bool
  default     = true
}

variable "enterprise_ebs_optimized" {
  description = "Enable EBS optimization for better storage performance"
  type        = bool
  default     = true
}

variable "enterprise_disable_api_termination" {
  description = "Disable API termination for production Red Hat 7 instances"
  type        = bool
  default     = false
}

variable "enterprise_shutdown_behavior" {
  description = "Instance shutdown behavior (stop or terminate)"
  type        = string
  default     = "stop"
  
  validation {
    condition     = contains(["stop", "terminate"], var.enterprise_shutdown_behavior)
    error_message = "Shutdown behavior must be either 'stop' or 'terminate'."
  }
}

variable "enterprise_source_dest_check" {
  description = "Enable source/destination checking (disable for NAT instances)"
  type        = bool
  default     = true
}

# ============================================================================
# High Availability Configuration
# ============================================================================

variable "enable_ha_deployment" {
  description = "Enable high availability deployment with secondary instance in different AZ"
  type        = bool
  default     = false
}

variable "enterprise_allocate_eip" {
  description = "Allocate Elastic IP addresses for Red Hat 7 instances"
  type        = bool
  default     = false
}

# ============================================================================
# Monitoring and Logging
# ============================================================================

variable "enable_cloudwatch_logs" {
  description = "Create CloudWatch log group for Red Hat 7 instance logs"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# ============================================================================
# Tagging and Metadata
# ============================================================================

variable "enterprise_additional_tags" {
  description = "Additional tags to apply to Red Hat 7 enterprise resources"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner of the Red Hat 7 deployment for resource tagging"
  type        = string
  default     = "terraform"
}

variable "cost_center" {
  description = "Cost center for billing and resource allocation"
  type        = string
  default     = "infrastructure"
}

# ============================================================================
# Example Variable Values (commented for reference)
# ============================================================================

# Example terraform.tfvars.enterprise configuration:
/*
# Core Configuration
enterprise_instance_type = "t3.medium"
enterprise_key_name      = "my-rhel-key"

# Network Configuration
enterprise_subnet_id              = "subnet-12345678"
enterprise_security_group_ids     = ["sg-12345678"]
enterprise_availability_zone      = "us-east-1a"
enterprise_associate_public_ip    = true

# Storage Configuration
enterprise_root_volume_type    = "gp3"
enterprise_root_volume_size    = 50
enterprise_encrypt_root_volume = true

# Advanced Configuration
enterprise_enable_monitoring       = true
enterprise_ebs_optimized           = true
enterprise_disable_api_termination = true
enterprise_allocate_eip            = true

# High Availability
enable_ha_deployment = true

# Monitoring
enable_cloudwatch_logs = true
log_retention_days     = 90

# Tagging
owner       = "devops-team"
cost_center = "engineering"

enterprise_additional_tags = {
  BusinessUnit = "Technology"
  Application  = "web-server"
  Backup       = "required"
}
*/
