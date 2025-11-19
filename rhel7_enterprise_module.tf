# ============================================================================
# RedHat 7 EC2 Instance Provisioning - Enterprise Module Configuration
# ============================================================================
# This configuration provisions a production-ready RedHat Enterprise Linux 7
# EC2 instance using the module from localterraform.com/ag/instance/aws
#
# Module Version: ~> 3.0
# Based on: RedHatProducts repository documentation
# Created: 2024-11-19
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

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# Data Sources
# ============================================================================

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the official RedHat 7 AMI (for reference/validation)
data "aws_ami" "redhat7" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official AWS account

  filter {
    name   = "name"
    values = ["RHEL-7.*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# VPC Infrastructure
# ============================================================================

# Create VPC for RedHat 7 deployment
resource "aws_vpc" "redhat_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "RedHat 7 Instance VPC"
    }
  )
}

# Create Internet Gateway for public access
resource "aws_internet_gateway" "redhat_igw" {
  vpc_id = aws_vpc.redhat_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-igw"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Create public subnet for RedHat instance
resource "aws_subnet" "redhat_public_subnet" {
  vpc_id                  = aws_vpc.redhat_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.associate_public_ip_address

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-subnet"
      Environment = var.environment
      Project     = var.project_name
      Type        = "Public"
      Tier        = "Application"
    }
  )
}

# Create route table for public subnet
resource "aws_route_table" "redhat_public_rt" {
  vpc_id = aws_vpc.redhat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redhat_igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-rt"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Associate route table with public subnet
resource "aws_route_table_association" "redhat_public_rta" {
  subnet_id      = aws_subnet.redhat_public_subnet.id
  route_table_id = aws_route_table.redhat_public_rt.id
}

# ============================================================================
# Security Groups
# ============================================================================

# Security group for RedHat 7 EC2 instance
resource "aws_security_group" "redhat7_sg" {
  name_prefix = "${var.project_name}-${var.environment}-redhat7-"
  description = "Security group for RedHat Enterprise Linux 7 instances"
  vpc_id      = aws_vpc.redhat_vpc.id

  # SSH access from allowed CIDR blocks
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP access (optional - for web servers)
  dynamic "ingress" {
    for_each = var.enable_http_access ? [1] : []
    content {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # HTTPS access (optional - for web servers)
  dynamic "ingress" {
    for_each = var.enable_https_access ? [1] : []
    content {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-redhat7-sg"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "RedHat 7 Instance Security"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# RedHat 7 EC2 Instance - Enterprise Module
# ============================================================================

module "vm_example_rh7" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 3.0"

  # ============================================================================
  # CORE INSTANCE PARAMETERS
  # ============================================================================
  
  # Instance type - determines compute resources (vCPU, memory)
  # Options: t3.micro (dev), t3.small, t3.medium (staging), t3.large/m5.large (prod)
  instance_type = var.instance_type

  # EC2 Key Pair name for SSH access - REQUIRED
  # Must exist in the target AWS region before deployment
  key_name = var.key_name

  # Instance name - used for the Name tag
  instance_name = "${var.project_name}-${var.environment}-redhat7"

  # ============================================================================
  # NETWORKING PARAMETERS
  # ============================================================================
  
  # VPC Subnet ID - instance will be launched in this subnet
  subnet_id = aws_subnet.redhat_public_subnet.id

  # Security group IDs - controls inbound/outbound traffic
  security_group_ids = [aws_security_group.redhat7_sg.id]

  # Availability Zone - precise placement within AWS region
  availability_zone = data.aws_availability_zones.available.names[0]

  # Associate public IP address for external access
  associate_public_ip_address = var.associate_public_ip_address

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================
  
  # Root volume type - EBS volume type for root filesystem
  # Options: gp2 (general purpose), gp3 (recommended - better cost/performance),
  #          io1/io2 (high IOPS for databases)
  root_volume_type = var.root_volume_type

  # Root volume size in GB
  # Minimum: 10 GB (OS only)
  # Recommended: 20-30 GB (small apps), 50-100 GB (standard), 100+ GB (databases)
  root_volume_size = var.root_volume_size

  # Enable encryption for root volume
  # CRITICAL: Always set to true for production environments
  # Uses AWS-managed encryption keys by default
  encrypt_root_volume = var.encrypt_root_volume

  # Delete volume when instance is terminated
  delete_on_termination = var.delete_on_termination

  # ============================================================================
  # REDHAT-SPECIFIC PARAMETERS
  # ============================================================================
  
  # Red Hat official AWS account ID for AMI selection
  # This ensures only official Red Hat AMIs are used
  ami_owner_id = var.ami_owner_id

  # AMI name filter pattern for RHEL 7
  # Automatically selects the most recent RHEL 7 x86_64 AMI
  ami_name_pattern = var.ami_name_pattern

  # ============================================================================
  # INITIALIZATION AND CONFIGURATION
  # ============================================================================
  
  # User data script - runs on first boot
  # Performs system updates, package installation, and initial configuration
  user_data = var.user_data_script

  # ============================================================================
  # TAGS AND METADATA
  # ============================================================================
  
  # Comprehensive tagging strategy for resource management
  # Tags enable: cost allocation, access control, automation, compliance tracking
  tags = merge(
    var.common_tags,
    {
      Name            = "${var.project_name}-${var.environment}-redhat7"
      Environment     = var.environment
      Project         = var.project_name
      OS              = "RHEL-7"
      OSVersion       = "RedHat Enterprise Linux 7"
      Owner           = var.owner
      CostCenter      = var.cost_center
      ManagedBy       = "Terraform"
      Module          = "localterraform.com/ag/instance/aws"
      ModuleVersion   = "~> 3.0"
      DeploymentDate  = timestamp()
      BackupPolicy    = var.backup_policy
      MaintenanceDay  = var.maintenance_window
      Compliance      = var.compliance_requirements
      SecurityLevel   = var.security_level
      DataClass       = var.data_classification
      ApplicationRole = var.application_role
      BusinessUnit    = var.business_unit
      Provisioner     = "Terraform-Enterprise-Module"
    }
  )

  # ============================================================================
  # MONITORING AND OBSERVABILITY
  # ============================================================================
  
  # Enable detailed CloudWatch monitoring (1-minute intervals vs 5-minute)
  monitoring = var.enable_detailed_monitoring

  # ============================================================================
  # LIFECYCLE MANAGEMENT
  # ============================================================================
  
  # Prevent accidental deletion in production
  # Note: This may need to be implemented at the module level
  # lifecycle {
  #   prevent_destroy = var.environment == "prod" ? true : false
  # }
}

# ============================================================================
# Elastic IP (Optional) - For static IP requirement
# ============================================================================

resource "aws_eip" "redhat7_eip" {
  count    = var.create_elastic_ip ? 1 : 0
  domain   = "vpc"
  instance = module.vm_example_rh7.instance_id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-redhat7-eip"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "Static IP for RedHat 7 Instance"
    }
  )

  depends_on = [aws_internet_gateway.redhat_igw]
}

# ============================================================================
# CloudWatch Alarms (Production Monitoring)
# ============================================================================

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-redhat7-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alert when CPU utilization exceeds ${var.cpu_alarm_threshold}%"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = module.vm_example_rh7.instance_id
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-cpu-alarm"
      Environment = var.environment
    }
  )
}

# Status Check Failed Alarm
resource "aws_cloudwatch_metric_alarm" "status_check_alarm" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-redhat7-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when instance status check fails"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = module.vm_example_rh7.instance_id
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-status-alarm"
      Environment = var.environment
    }
  )
}

# ============================================================================
# END OF CONFIGURATION
# ============================================================================
