# ============================================================================
# RedHat 7 EC2 Instance - Enterprise Module Variables
# ============================================================================
# This file defines all variables for the RedHat 7 EC2 instance deployment
# using the enterprise module from localterraform.com/ag/instance/aws
#
# Variables are organized by category:
# - AWS Configuration
# - Project Configuration
# - Network Configuration
# - Instance Configuration
# - Storage Configuration
# - Security Configuration
# - RedHat-Specific Configuration
# - Tags and Metadata
# - Monitoring and Alerts
# ============================================================================

# ============================================================================
# AWS CONFIGURATION
# ============================================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region code (e.g., us-east-1, eu-west-1)."
  }
}

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "redhat-deployment"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "qa"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, qa."
  }
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "create_elastic_ip" {
  description = "Whether to create and associate an Elastic IP (static IP)"
  type        = bool
  default     = false
}

# ============================================================================
# INSTANCE CONFIGURATION
# ============================================================================

variable "instance_type" {
  description = <<-EOT
    EC2 instance type - determines CPU, memory, and network performance.
    
    Recommendations:
    - Development/Testing: t3.micro (2 vCPU, 1 GB RAM)
    - Small Applications: t3.small (2 vCPU, 2 GB RAM)
    - Medium Workloads: t3.medium (2 vCPU, 4 GB RAM)
    - Production Apps: m5.large (2 vCPU, 8 GB RAM)
    - High Performance: m5.xlarge (4 vCPU, 16 GB RAM)
    - Compute Intensive: c5.xlarge (4 vCPU, 8 GB RAM)
  EOT
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
      "m6i.large", "m6i.xlarge", "m6i.2xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
      "r5.large", "r5.xlarge", "r5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid and supported EC2 instance type."
  }
}

variable "key_name" {
  description = <<-EOT
    Name of the AWS EC2 Key Pair for SSH access.
    REQUIRED - Must be created in the target AWS region before deployment.
    
    To create a key pair:
    aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
    chmod 400 my-key.pem
  EOT
  type        = string

  validation {
    condition     = length(var.key_name) > 0
    error_message = "Key name is required and cannot be empty."
  }
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "root_volume_type" {
  description = <<-EOT
    EBS volume type for root filesystem.
    
    Options:
    - gp2: General Purpose SSD (3 IOPS/GB, max 16,000 IOPS) - Legacy
    - gp3: General Purpose SSD (3,000 IOPS baseline, configurable) - RECOMMENDED
    - io1: Provisioned IOPS SSD (up to 64,000 IOPS) - High performance databases
    - io2: Provisioned IOPS SSD (up to 64,000 IOPS) - Mission-critical workloads
    
    Cost comparison: gp2 < gp3 < io1 < io2
    Performance: gp3 offers best price/performance ratio
  EOT
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_size" {
  description = <<-EOT
    Root volume size in GB.
    
    Recommendations:
    - Minimum: 10 GB (RHEL OS only)
    - Small Applications: 20-30 GB
    - Standard Deployments: 50-100 GB
    - Database Servers: 100-500 GB
    - Large Applications: 500+ GB
    
    Default: 20 GB (suitable for small to medium applications)
  EOT
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 10 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 10 GB and 16,384 GB (16 TiB)."
  }
}

variable "encrypt_root_volume" {
  description = <<-EOT
    Enable encryption for root volume.
    
    CRITICAL SECURITY REQUIREMENT:
    - MUST be set to true for production environments
    - Uses AWS-managed encryption keys (AES-256) by default
    - No performance impact
    - Meets compliance requirements (HIPAA, PCI-DSS, SOC 2)
    
    For additional security, configure KMS custom keys separately.
  EOT
  type        = bool
  default     = true
}

variable "delete_on_termination" {
  description = "Delete root volume when instance is terminated (recommended for non-production)"
  type        = bool
  default     = true
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "allowed_ssh_cidrs" {
  description = <<-EOT
    List of CIDR blocks allowed to SSH to the instance (port 22).
    
    SECURITY BEST PRACTICE:
    - NEVER use ["0.0.0.0/0"] in production
    - Restrict to your organization's IP ranges
    - Use VPN or bastion host CIDR blocks
    - Consider AWS Systems Manager Session Manager as an alternative
    
    Example: ["203.0.113.0/24", "198.51.100.0/24"]
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "enable_http_access" {
  description = "Enable HTTP (port 80) access from the internet"
  type        = bool
  default     = false
}

variable "enable_https_access" {
  description = "Enable HTTPS (port 443) access from the internet"
  type        = bool
  default     = false
}

# ============================================================================
# REDHAT-SPECIFIC CONFIGURATION
# ============================================================================

variable "ami_owner_id" {
  description = <<-EOT
    AWS account ID for Red Hat official AMIs.
    Default: 309956199498 (Red Hat, Inc. official account)
    
    This ensures only official, supported Red Hat Enterprise Linux AMIs are used.
    DO NOT CHANGE unless using a different AMI source.
  EOT
  type        = string
  default     = "309956199498"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.ami_owner_id))
    error_message = "AMI owner ID must be a 12-digit AWS account ID."
  }
}

variable "ami_name_pattern" {
  description = <<-EOT
    AMI name filter pattern for RHEL 7 selection.
    Default: "RHEL-7.*-x86_64-*"
    
    Pattern automatically selects:
    - Red Hat Enterprise Linux 7
    - x86_64 architecture (64-bit)
    - Most recent version available
    
    DO NOT CHANGE unless you need a specific RHEL 7 version.
  EOT
  type        = string
  default     = "RHEL-7.*-x86_64-*"
}

variable "user_data_script" {
  description = <<-EOT
    User data script executed on instance first boot.
    Performs system initialization, updates, and configuration.
    
    Default script:
    - Updates all system packages
    - Installs common utilities (htop, wget, curl, vim)
    - Creates welcome message (MOTD)
    - Enables and starts SSH daemon
    - Logs deployment completion
  EOT
  type        = string
  default     = <<-EOF
    #!/bin/bash
    # ===========================================================================
    # RedHat 7 Instance Initialization Script
    # ===========================================================================
    # This script runs on the first boot of the EC2 instance
    # Logs: /var/log/user-data.log and /var/log/deployment.log
    # ===========================================================================
    
    set -e
    exec > >(tee -a /var/log/user-data.log) 2>&1
    
    echo "=========================================="
    echo "Starting RedHat 7 Instance Configuration"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "=========================================="
    
    # Update system packages
    echo "[$(date)] Updating system packages..."
    yum update -y
    
    # Install essential utilities
    echo "[$(date)] Installing essential packages..."
    yum install -y \
      htop \
      wget \
      curl \
      vim \
      net-tools \
      bind-utils \
      telnet \
      nc \
      lsof \
      sysstat \
      git
    
    # Configure system timezone
    echo "[$(date)] Configuring timezone..."
    timedatectl set-timezone UTC
    
    # Enable and configure firewall (optional)
    # echo "[$(date)] Configuring firewall..."
    # systemctl enable firewalld
    # systemctl start firewalld
    
    # Create welcome message
    echo "[$(date)] Creating welcome message..."
    cat > /etc/motd << 'MOTD'
    
    ================================================================================
                    Welcome to RedHat Enterprise Linux 7 Instance
    ================================================================================
    
    This instance was provisioned using Terraform Enterprise Module
    Module: localterraform.com/ag/instance/aws version ~> 3.0
    
    System Information:
    - OS: Red Hat Enterprise Linux 7
    - Deployment: Production-Ready Configuration
    - Management: Infrastructure as Code (Terraform)
    
    Useful Commands:
    ┌──────────────────────────────────────────────────────────────────────┐
    │  System Management                                                   │
    ├──────────────────────────────────────────────────────────────────────┤
    │  sudo yum update              Update system packages                 │
    │  sudo systemctl status <svc>  Check service status                   │
    │  sudo journalctl -xe          View system logs                       │
    │  df -h                        Check disk usage                       │
    │  free -h                      Check memory usage                     │
    │  top / htop                   Monitor processes                      │
    │  netstat -tulpn              Check listening ports                   │
    │  cat /etc/redhat-release     Display RHEL version                    │
    └──────────────────────────────────────────────────────────────────────┘
    
    Security Reminders:
    - Keep system updated: sudo yum update -y
    - Review security logs: sudo grep -i error /var/log/messages
    - Monitor disk space: df -h
    - Check failed login attempts: sudo lastb
    
    Documentation: Refer to deployment documentation for architecture details
    
    ================================================================================
    
MOTD
    
    # Configure SSH
    echo "[$(date)] Configuring SSH service..."
    systemctl enable sshd
    systemctl start sshd
    
    # Set up system monitoring
    echo "[$(date)] Enabling system monitoring..."
    systemctl enable sysstat
    systemctl start sysstat
    
    # Create deployment log
    echo "[$(date)] Deployment completed successfully" >> /var/log/deployment.log
    echo "Instance ID: $(ec2-metadata --instance-id 2>/dev/null | cut -d' ' -f2)" >> /var/log/deployment.log
    echo "Instance Type: $(ec2-metadata --instance-type 2>/dev/null | cut -d' ' -f2)" >> /var/log/deployment.log
    echo "Availability Zone: $(ec2-metadata --availability-zone 2>/dev/null | cut -d' ' -f2)" >> /var/log/deployment.log
    
    echo "=========================================="
    echo "RedHat 7 Instance Configuration Complete"
    echo "Date: $(date)"
    echo "=========================================="
    
    # Optional: Send completion notification (configure SNS topic if needed)
    # aws sns publish --topic-arn arn:aws:sns:region:account:topic --message "Instance deployment completed"
    
  EOF
}

# ============================================================================
# TAGS AND METADATA
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Repository  = "deployVM"
    ManagedBy   = "Terraform-Enterprise"
    Provisioner = "Enterprise-Module"
  }
}

variable "owner" {
  description = "Owner of the resources (team or individual)"
  type        = string
  default     = "DevOps-Team"
}

variable "cost_center" {
  description = "Cost center for billing and cost allocation"
  type        = string
  default     = "Engineering"
}

variable "business_unit" {
  description = "Business unit that owns this resource"
  type        = string
  default     = "Technology"
}

variable "application_role" {
  description = "Application role or function (e.g., web-server, app-server, database)"
  type        = string
  default     = "application-server"
}

variable "backup_policy" {
  description = "Backup policy for the instance (e.g., daily, weekly, none)"
  type        = string
  default     = "daily"

  validation {
    condition     = contains(["none", "daily", "weekly", "monthly"], var.backup_policy)
    error_message = "Backup policy must be one of: none, daily, weekly, monthly."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window (day of week)"
  type        = string
  default     = "Sunday"

  validation {
    condition = contains([
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ], var.maintenance_window)
    error_message = "Maintenance window must be a valid day of the week."
  }
}

variable "compliance_requirements" {
  description = "Compliance requirements (e.g., HIPAA, PCI-DSS, SOC2)"
  type        = string
  default     = "General"
}

variable "security_level" {
  description = "Security classification level (e.g., Public, Internal, Confidential, Restricted)"
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.security_level)
    error_message = "Security level must be one of: Public, Internal, Confidential, Restricted."
  }
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Sensitive", "Restricted"], var.data_classification)
    error_message = "Data classification must be one of: Public, Internal, Sensitive, Restricted."
  }
}

# ============================================================================
# MONITORING AND ALERTS
# ============================================================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute intervals instead of 5-minute)"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for instance monitoring"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold >= 1 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 1 and 100 percent."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}

# ============================================================================
# END OF VARIABLES
# ============================================================================
