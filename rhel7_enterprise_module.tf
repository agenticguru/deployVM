# ============================================================================
# Red Hat 7 EC2 Instance Provisioning using Internal Terraform Enterprise Module
# ============================================================================
# This configuration provisions Red Hat 7 EC2 instances using the internal
# Terraform Enterprise module at localterraform.com/ag/instance/aws
#
# Based on parameters from RedHatProducts repository documentation:
# - Official Red Hat AMI (Owner: 309956199498)
# - RHEL 7.x x86_64 architecture
# - Default instance type: t3.micro (customizable)
# - SSH key-based authentication
# - Encrypted root volumes for security
# - VPC integration with security groups
# ============================================================================

# ============================================================================
# Data Source: Red Hat 7 AMI Selection
# ============================================================================
# Automatically selects the most recent official Red Hat 7 AMI
# Based on RedHatProducts repository AMI configuration

data "aws_ami" "rhel7_enterprise" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat AWS Account

  filter {
    name   = "name"
    values = ["RHEL-7.*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# Local Values for Enterprise Configuration
# ============================================================================

locals {
  # Enterprise deployment tags
  enterprise_tags = {
    Environment      = var.environment
    Project          = var.project_name
    ManagedBy        = "terraform"
    Repository       = "deployVM"
    Module           = "localterraform.com/ag/instance/aws"
    OperatingSystem  = "RHEL-7"
    Deployment       = "enterprise"
    Owner            = var.owner
    CostCenter       = var.cost_center
    Compliance       = "required"
  }

  # Instance naming convention for enterprise deployment
  enterprise_instance_name = "${var.project_name}-${var.environment}-rhel7-enterprise-${formatdate("YYYYMMDD", timestamp())}"
}

# ============================================================================
# Primary Red Hat 7 Enterprise Instance
# ============================================================================
# Provisions a Red Hat 7 EC2 instance using the internal Terraform Enterprise
# module with parameters gathered from RedHatProducts documentation

module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # ========================================
  # Required Instance Configuration Parameters
  # ========================================
  
  # AMI Configuration - Using official Red Hat 7 AMI
  ami_id        = data.aws_ami.rhel7_enterprise.id
  instance_type = var.enterprise_instance_type
  
  # SSH Key Configuration - Required for instance access
  key_name = var.enterprise_key_name

  # Instance Naming - Enterprise naming convention
  instance_name = local.enterprise_instance_name

  # ========================================
  # Network Configuration Parameters
  # ========================================
  # Gathered from RedHatProducts documentation:
  # - VPC subnet integration required
  # - Security groups for access control
  # - Availability zone specification
  # - Public IP association
  
  subnet_id              = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
  security_group_ids     = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
  availability_zone      = coalesce(var.enterprise_availability_zone, data.aws_availability_zones.available.names[0])
  associate_public_ip    = var.enterprise_associate_public_ip

  # ========================================
  # Storage Configuration Parameters
  # ========================================
  # Based on RedHatProducts recommendations:
  # - Minimum 10GB for RHEL OS
  # - Recommended 20GB+ for applications
  # - Encryption enabled for security compliance
  # - gp3 volumes for better performance/cost ratio
  
  root_volume_type    = var.enterprise_root_volume_type
  root_volume_size    = var.enterprise_root_volume_size
  encrypt_root_volume = var.enterprise_encrypt_root_volume
  kms_key_id          = var.enterprise_kms_key_id

  # Additional EBS volumes (optional)
  ebs_block_device = var.enterprise_additional_volumes

  # ========================================
  # Advanced Instance Configuration
  # ========================================
  
  # User Data - Bootstrap scripts for RHEL configuration
  user_data                = var.enterprise_user_data != null ? var.enterprise_user_data : file("${path.module}/scripts/rhel7_bootstrap.sh")
  user_data_replace_on_change = var.enterprise_user_data_replace_on_change

  # IAM Instance Profile - For AWS service permissions
  iam_instance_profile = var.enterprise_iam_instance_profile

  # Monitoring and Performance
  monitoring    = var.enterprise_enable_monitoring
  ebs_optimized = var.enterprise_ebs_optimized

  # Instance Protection
  disable_api_termination              = var.enterprise_disable_api_termination
  instance_initiated_shutdown_behavior = var.enterprise_shutdown_behavior

  # Source/Destination Check (for NAT/routing instances)
  source_dest_check = var.enterprise_source_dest_check

  # Metadata Configuration (IMDSv2)
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # ========================================
  # Resource Tagging
  # ========================================
  tags = merge(
    local.enterprise_tags,
    var.enterprise_additional_tags,
    {
      Name = local.enterprise_instance_name
      AMI  = data.aws_ami.rhel7_enterprise.id
    }
  )

  # Volume tags
  volume_tags = merge(
    local.enterprise_tags,
    {
      Name       = "${local.enterprise_instance_name}-root-volume"
      VolumeType = var.enterprise_root_volume_type
      Encrypted  = var.enterprise_encrypt_root_volume
    }
  )
}

# ============================================================================
# High Availability Configuration (Optional)
# ============================================================================
# Deploy secondary instance in different availability zone for HA

module "rhel7_enterprise_instance_ha" {
  count = var.enable_ha_deployment ? 1 : 0

  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Instance Configuration
  ami_id        = data.aws_ami.rhel7_enterprise.id
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name
  instance_name = "${local.enterprise_instance_name}-ha"

  # Network Configuration - Different AZ for HA
  subnet_id              = var.enterprise_subnet_id_secondary != null ? var.enterprise_subnet_id_secondary : aws_subnet.public.id
  security_group_ids     = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
  availability_zone      = data.aws_availability_zones.available.names[1]
  associate_public_ip    = var.enterprise_associate_public_ip

  # Storage Configuration - Same as primary
  root_volume_type    = var.enterprise_root_volume_type
  root_volume_size    = var.enterprise_root_volume_size
  encrypt_root_volume = var.enterprise_encrypt_root_volume
  kms_key_id          = var.enterprise_kms_key_id

  # Advanced Configuration
  user_data                = var.enterprise_user_data != null ? var.enterprise_user_data : file("${path.module}/scripts/rhel7_bootstrap.sh")
  iam_instance_profile     = var.enterprise_iam_instance_profile
  monitoring               = var.enterprise_enable_monitoring
  ebs_optimized            = var.enterprise_ebs_optimized
  disable_api_termination  = var.enterprise_disable_api_termination

  # Metadata Configuration
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Resource Tagging
  tags = merge(
    local.enterprise_tags,
    var.enterprise_additional_tags,
    {
      Name = "${local.enterprise_instance_name}-ha"
      Role = "secondary"
      AMI  = data.aws_ami.rhel7_enterprise.id
    }
  )

  volume_tags = merge(
    local.enterprise_tags,
    {
      Name       = "${local.enterprise_instance_name}-ha-root-volume"
      VolumeType = var.enterprise_root_volume_type
      Encrypted  = var.enterprise_encrypt_root_volume
    }
  )
}

# ============================================================================
# Elastic IP Association (Optional)
# ============================================================================
# Static IP address for production workloads

resource "aws_eip" "rhel7_enterprise" {
  count = var.enterprise_allocate_eip ? 1 : 0

  instance = module.rhel7_enterprise_instance.instance_id
  domain   = "vpc"

  tags = merge(
    local.enterprise_tags,
    {
      Name = "${local.enterprise_instance_name}-eip"
    }
  )

  depends_on = [module.rhel7_enterprise_instance]
}

resource "aws_eip" "rhel7_enterprise_ha" {
  count = var.enable_ha_deployment && var.enterprise_allocate_eip ? 1 : 0

  instance = module.rhel7_enterprise_instance_ha[0].instance_id
  domain   = "vpc"

  tags = merge(
    local.enterprise_tags,
    {
      Name = "${local.enterprise_instance_name}-ha-eip"
    }
  )

  depends_on = [module.rhel7_enterprise_instance_ha]
}

# ============================================================================
# CloudWatch Log Group for Instance Logs (Optional)
# ============================================================================

resource "aws_cloudwatch_log_group" "rhel7_enterprise" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/ec2/${local.enterprise_instance_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enterprise_kms_key_id

  tags = merge(
    local.enterprise_tags,
    {
      Name = "${local.enterprise_instance_name}-logs"
    }
  )
}

# ============================================================================
# Outputs for Enterprise Deployment
# ============================================================================

output "rhel7_enterprise_primary" {
  description = "Primary RHEL 7 enterprise instance details"
  value = {
    instance_id       = module.rhel7_enterprise_instance.instance_id
    ami_id            = data.aws_ami.rhel7_enterprise.id
    ami_name          = data.aws_ami.rhel7_enterprise.name
    public_ip         = module.rhel7_enterprise_instance.public_ip
    private_ip        = try(module.rhel7_enterprise_instance.private_ip, null)
    availability_zone = try(module.rhel7_enterprise_instance.availability_zone, null)
    instance_type     = var.enterprise_instance_type
    subnet_id         = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
    eip               = var.enterprise_allocate_eip ? aws_eip.rhel7_enterprise[0].public_ip : null
  }
  sensitive = false
}

output "rhel7_enterprise_ha" {
  description = "High availability RHEL 7 instance details (if enabled)"
  value = var.enable_ha_deployment ? {
    instance_id       = module.rhel7_enterprise_instance_ha[0].instance_id
    public_ip         = module.rhel7_enterprise_instance_ha[0].public_ip
    private_ip        = try(module.rhel7_enterprise_instance_ha[0].private_ip, null)
    availability_zone = try(module.rhel7_enterprise_instance_ha[0].availability_zone, null)
    eip               = var.enterprise_allocate_eip ? aws_eip.rhel7_enterprise_ha[0].public_ip : null
  } : null
  sensitive = false
}

output "rhel7_enterprise_ssh_command" {
  description = "SSH command to connect to the primary RHEL 7 enterprise instance"
  value       = "ssh -i ${var.enterprise_key_name}.pem ec2-user@${var.enterprise_allocate_eip ? aws_eip.rhel7_enterprise[0].public_ip : module.rhel7_enterprise_instance.public_ip}"
}

output "rhel7_enterprise_deployment_summary" {
  description = "Complete deployment summary"
  value = {
    module_source     = "localterraform.com/ag/instance/aws"
    operating_system  = "Red Hat Enterprise Linux 7"
    ami_id            = data.aws_ami.rhel7_enterprise.id
    ami_name          = data.aws_ami.rhel7_enterprise.name
    instance_count    = var.enable_ha_deployment ? 2 : 1
    instance_type     = var.enterprise_instance_type
    encryption        = var.enterprise_encrypt_root_volume
    monitoring        = var.enterprise_enable_monitoring
    high_availability = var.enable_ha_deployment
    elastic_ip        = var.enterprise_allocate_eip
    environment       = var.environment
    project           = var.project_name
  }
}
