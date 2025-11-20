# ============================================================================
# RedHat 8 VM Provisioning using Internal Terraform Module
# ============================================================================
# 
# This configuration provisions a RedHat Enterprise Linux 8 VM using the
# module from the internal Terraform registry at localterraform.com/ag/instance/aws
#
# Requirements:
# - VPC and subnet infrastructure (provided by main.tf)
# - Security groups configured for RHEL instances
# - AWS credentials with appropriate permissions
# - EC2 key pair for SSH access
#
# Module Source: localterraform.com/ag/instance/aws
# ============================================================================

# Deploy RedHat 8 instance using the internal Terraform registry module
module "redhat8_production" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================
  # Subnet where the instance will be deployed
  # Uses the public subnet created in main.tf for internet connectivity
  subnet_id = aws_subnet.public.id

  # Security groups for network access control
  # Uses the RedHat security group configured in main.tf with SSH, HTTP, HTTPS
  security_group_ids = [aws_security_group.redhat_sg.id]

  # Availability zone for instance placement
  # Ensures instance is placed in the same AZ as the subnet
  availability_zone = data.aws_availability_zones.available.names[0]

  # ============================================================================
  # COMPUTE CONFIGURATION
  # ============================================================================
  # Instance type selection based on workload requirements
  # t3.micro: Development/testing (2 vCPU, 1 GB RAM)
  # t3.medium: Production workloads (2 vCPU, 4 GB RAM) - recommended
  # m5.large: High-performance applications (2 vCPU, 8 GB RAM)
  instance_type = var.instance_type

  # SSH key pair for secure access to the instance
  # Must exist in the AWS region before deployment
  key_name = var.key_name

  # Instance name - appears in AWS Console and used for identification
  # Following naming convention: {project}-{environment}-{os}-{purpose}
  instance_name = "${var.project_name}-${var.environment}-rhel8-production"

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================
  # Root volume type - EBS volume type for boot disk
  # gp3: Latest generation SSD with better performance/cost ratio (recommended)
  # gp2: Previous generation SSD for cost optimization
  # io1/io2: Provisioned IOPS for high-performance workloads
  root_volume_type = var.root_volume_type

  # Root volume size in GB
  # Minimum: 10 GB for RHEL 8 OS
  # Recommended: 20-50 GB for standard applications
  # Enterprise: 100+ GB for data-intensive workloads
  root_volume_size = var.root_volume_size

  # Enable encryption for data at rest
  # Recommended: true for all production workloads
  # Required for compliance standards (HIPAA, PCI-DSS, SOC 2)
  encrypt_root_volume = var.encrypt_root_volume

  # ============================================================================
  # RESOURCE TAGGING
  # ============================================================================
  # Comprehensive tagging strategy for resource management, cost allocation,
  # and compliance tracking. Following organizational standards.
  tags = {
    # Core identification tags
    Name        = "${var.project_name}-${var.environment}-rhel8-production"
    Environment = var.environment
    Project     = var.project_name

    # Operational tags
    OS             = "RHEL-8"
    OSVersion      = "RedHat Enterprise Linux 8"
    Module         = "localterraform.com/ag/instance/aws"
    ManagedBy      = "Terraform"
    DeploymentDate = timestamp()

    # Ownership and accountability
    Owner      = "Platform Engineering Team"
    CostCenter = "Engineering"
    Team       = "Infrastructure"

    # Compliance and security
    Compliance        = "Enterprise"
    SecurityLevel     = "Standard"
    DataClass         = "Internal"
    EncryptionEnabled = tostring(var.encrypt_root_volume)

    # Operational management
    BackupPolicy      = "Daily"
    MaintenanceWindow = "Sun:03:00-Sun:05:00"
    MonitoringEnabled = "true"
    PatchGroup        = "production-rhel8"

    # Application context
    Application = "Enterprise Application Server"
    Tier        = "Application"
    Purpose     = "Production VM"
  }
}

# ============================================================================
# OUTPUTS FOR REDHAT 8 INSTANCE
# ============================================================================

# Instance identifier for reference in other resources and AWS operations
output "rhel8_instance_id" {
  description = "ID of the RedHat 8 EC2 instance"
  value       = module.redhat8_production.instance_id
}

# Public IP address for external access and SSH connectivity
output "rhel8_public_ip" {
  description = "Public IP address of the RedHat 8 instance"
  value       = module.redhat8_production.public_ip
}

# Private IP address for internal VPC communication
output "rhel8_private_ip" {
  description = "Private IP address of the RedHat 8 instance within VPC"
  value       = module.redhat8_production.private_ip
}

# Availability zone confirmation for multi-AZ planning
output "rhel8_availability_zone" {
  description = "Availability zone where the RedHat 8 instance is deployed"
  value       = module.redhat8_production.availability_zone
}

# SSH connection command for quick access
output "rhel8_ssh_command" {
  description = "SSH command to connect to the RedHat 8 instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.redhat8_production.public_ip}"
}

# Comprehensive deployment summary
output "rhel8_deployment_summary" {
  description = "Complete deployment information for the RedHat 8 instance"
  value = {
    instance_id       = module.redhat8_production.instance_id
    instance_name     = "${var.project_name}-${var.environment}-rhel8-production"
    instance_type     = var.instance_type
    public_ip         = module.redhat8_production.public_ip
    private_ip        = module.redhat8_production.private_ip
    availability_zone = module.redhat8_production.availability_zone
    subnet_id         = aws_subnet.public.id
    security_groups   = [aws_security_group.redhat_sg.id]
    vpc_id            = aws_vpc.main.id
    os                = "RHEL-8"
    environment       = var.environment
    project           = var.project_name
    volume_encrypted  = var.encrypt_root_volume
    volume_size       = var.root_volume_size
    volume_type       = var.root_volume_type
  }
}
