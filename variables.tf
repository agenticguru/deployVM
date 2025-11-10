# AWS Configuration Variables
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "redhat-deployment"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Note: Restrict this in production
}

# EC2 Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "m5.2xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  default     = "my-redhat-key"
}

# Storage Configuration
variable "root_volume_type" {
  description = "Type of root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 10 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 10 and 1000 GB."
  }
}

variable "encrypt_root_volume" {
  description = "Enable encryption for root volume"
  type        = bool
  default     = true
}

# User Data Configuration
variable "user_data_script" {
  description = "User data script to run on instance startup"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y htop wget curl vim
    
    # Create a welcome message
    cat > /etc/motd << 'MOTD'
    
    ================================================
    Welcome to RedHat Enterprise Linux 7 Instance
    ================================================
    
    This instance was deployed using Terraform
    Project: RedHat Deployment
    OS: RHEL 7
    
    Useful commands:
    - sudo yum update: Update packages
    - sudo systemctl status: Check service status
    - df -h: Check disk usage
    - free -h: Check memory usage
    - top: Monitor processes
    
    ================================================
    
MOTD
    
    # Enable and start services
    systemctl enable sshd
    systemctl start sshd
    
    # Log deployment completion
    echo "$(date): RedHat 7 instance deployment completed successfully" >> /var/log/deployment.log
  EOF
}