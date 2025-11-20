#===============================================================================
# RedHat Enterprise Linux 8 VM Provisioning
#===============================================================================
# This Terraform configuration provisions a RedHat 8 VM on AWS using a 
# custom module from the local Terraform registry.
#
# Module Source: localterraform.com/ag/instance/aws
# Operating System: RedHat Enterprise Linux 8 (RHEL 8)
# Cloud Provider: AWS (Amazon Web Services)
#===============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#-------------------------------------------------------------------------------
# Data Source: Get the latest RedHat 8 AMI
#-------------------------------------------------------------------------------
# This data source automatically fetches the most recent official RHEL 8 AMI
# from Red Hat's AWS account (309956199498), ensuring you always deploy with
# the latest patches and security updates.
#-------------------------------------------------------------------------------
data "aws_ami" "redhat8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat's official AWS account

  filter {
    name   = "name"
    values = ["RHEL-8.*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

#-------------------------------------------------------------------------------
# Module: RedHat 8 Instance Provisioning
#-------------------------------------------------------------------------------
# This module provisions a complete RedHat 8 EC2 instance with:
# - Proper networking configuration (VPC, subnet, security groups)
# - Encrypted root volume for data security
# - Comprehensive tagging for resource management
# - High-availability zone placement
#-------------------------------------------------------------------------------
module "redhat8_vm" {
  source = "localterraform.com/ag/instance/aws"

  #-----------------------------------------------------------------------------
  # Instance Configuration
  #-----------------------------------------------------------------------------
  # instance_type: Determines CPU, memory, and network capacity
  # Options: t3.micro (2 vCPU, 1GB), t3.small (2 vCPU, 2GB), 
  #          t3.medium (2 vCPU, 4GB), m5.large (2 vCPU, 8GB)
  instance_type = "t3.medium"

  # key_name: SSH key pair for secure access to the instance
  # Must be created in AWS EC2 console beforehand
  key_name = var.key_name

  # instance_name: Friendly name displayed in AWS Console
  # Best practice: Include environment and purpose
  instance_name = "${var.project_name}-${var.environment}-rhel8-vm"

  #-----------------------------------------------------------------------------
  # Network Configuration
  #-----------------------------------------------------------------------------
  # subnet_id: VPC subnet where the instance will be launched
  # Use public subnet for internet-facing instances
  # Use private subnet for internal/backend instances
  subnet_id = aws_subnet.public.id

  # security_group_ids: Firewall rules controlling inbound/outbound traffic
  # Multiple security groups can be attached for layered security
  security_group_ids = [aws_security_group.redhat_sg.id]

  # availability_zone: Physical location within AWS region
  # Critical for high availability and disaster recovery planning
  availability_zone = data.aws_availability_zones.available.names[0]

  #-----------------------------------------------------------------------------
  # Storage Configuration
  #-----------------------------------------------------------------------------
  # root_volume_type: EBS volume type for root filesystem
  # gp3: Latest generation general purpose SSD (recommended)
  # - Better performance than gp2 at same or lower cost
  # - 3,000 IOPS baseline, up to 16,000 IOPS
  # - 125 MB/s baseline throughput
  root_volume_type = "gp3"

  # root_volume_size: Root disk size in gigabytes
  # Sizing guidelines:
  # - Minimum 10 GB (RHEL 8 base installation)
  # - 30-50 GB recommended for applications
  # - 100+ GB for database or high-storage workloads
  root_volume_size = 50

  # encrypt_root_volume: Enable EBS encryption at rest
  # Strongly recommended for production and compliance requirements
  # - Uses AWS managed encryption keys by default
  # - No performance impact on modern instance types
  # - Required for PCI-DSS, HIPAA, and other compliance frameworks
  encrypt_root_volume = true

  #-----------------------------------------------------------------------------
  # Resource Tags
  #-----------------------------------------------------------------------------
  # Tags enable resource organization, cost tracking, and automation
  # These are merged with the instance_name tag automatically
  tags = {
    Environment  = var.environment
    OS           = "RHEL-8"
    OSVersion    = "RedHat-8.x"
    Project      = var.project_name
    ManagedBy    = "Terraform"
    Owner        = "DevOps-Team"
    CostCenter   = "Engineering"
    Backup       = "Daily"
    Compliance   = "Standard"
    Purpose      = "Application-Server"
    DeployedDate = timestamp()
  }
}

#===============================================================================
# OUTPUTS
#===============================================================================
# These outputs expose important information about the deployed VM
# Use: terraform output <output_name> to retrieve values
#===============================================================================

output "rhel8_instance_id" {
  description = "The unique identifier of the RedHat 8 EC2 instance"
  value       = module.redhat8_vm.instance_id
}

output "rhel8_public_ip" {
  description = "Public IP address for external access (if in public subnet)"
  value       = module.redhat8_vm.public_ip
}

output "rhel8_private_ip" {
  description = "Private IP address for internal VPC communication"
  value       = module.redhat8_vm.private_ip
}

output "rhel8_availability_zone" {
  description = "AWS availability zone where the instance is running"
  value       = module.redhat8_vm.availability_zone
}

output "rhel8_ami_id" {
  description = "AMI ID used for the RHEL 8 instance"
  value       = data.aws_ami.redhat8.id
}

output "rhel8_ami_name" {
  description = "Name of the RHEL 8 AMI (includes version information)"
  value       = data.aws_ami.redhat8.name
}

output "rhel8_ssh_connection" {
  description = "SSH command to connect to the RedHat 8 instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.redhat8_vm.public_ip}"
}

#===============================================================================
# DEPLOYMENT NOTES
#===============================================================================
# 
# Prerequisites:
# 1. AWS credentials configured (AWS CLI or environment variables)
# 2. SSH key pair created in AWS EC2 (matching var.key_name)
# 3. VPC and subnet infrastructure already provisioned
# 4. Appropriate IAM permissions for EC2, VPC, and AMI operations
#
# Deployment Steps:
# 1. Initialize Terraform:    terraform init
# 2. Review changes:          terraform plan
# 3. Apply configuration:     terraform apply
# 4. View outputs:            terraform output
# 5. Connect to VM:           Use ssh_connection output value
#
# Default RHEL 8 User: ec2-user
# 
# Post-Deployment:
# - Register with Red Hat Subscription Manager (RHSM)
# - Update packages: sudo yum update -y
# - Configure firewall: sudo firewall-cmd --permanent --add-service=<service>
# - Install required applications and dependencies
# - Configure monitoring and logging
#
# Security Best Practices:
# - Restrict security group rules to specific IPs/ranges
# - Regularly apply security patches and updates
# - Enable CloudWatch monitoring and logging
# - Implement regular automated backups
# - Use IAM roles instead of embedding credentials
# - Enable AWS Config for compliance tracking
#
# Estimated Costs (us-east-1):
# - t3.medium instance: ~$30/month
# - gp3 50GB storage: ~$4/month
# - Data transfer: Variable based on usage
# Total estimated: ~$35-50/month (excluding data transfer)
#
#===============================================================================
