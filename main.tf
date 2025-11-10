# Configure the AWS Provider
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

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create security group for RedHat instances
resource "aws_security_group" "redhat_sg" {
  name_prefix = "${var.project_name}-redhat-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RedHat 7 instances"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP access (optional)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access (optional)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-redhat-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Deploy RedHat 7 instance using the module from RedHatProducts repository
module "redhat7_instance" {
  source = "../RedHatProducts/RedHatProducts/modules/redhat7"

  instance_type = var.instance_type
  key_name      = var.key_name
  instance_name = "${var.project_name}-${var.environment}-redhat7"
}

# Attach security group to the instance (using aws_network_interface_sg_attachment)
# Note: This is a workaround since the basic module doesn't support security groups directly
resource "aws_instance" "redhat7_enhanced" {
  ami                         = data.aws_ami.redhat7.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.redhat_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.encrypt_root_volume
    delete_on_termination = true
  }

  user_data = var.user_data_script

  tags = {
    Name        = "${var.project_name}-${var.environment}-redhat7-enhanced"
    Environment = var.environment
    Project     = var.project_name
    OS          = "RHEL-7"
    Module      = "Enhanced RedHat7 Deployment"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for RedHat 7 AMI (same as in the module)
data "aws_ami" "redhat7" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-7.*-x86_64-*"]
  }
}