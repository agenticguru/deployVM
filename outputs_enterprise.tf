# ============================================================================
# Output Definitions for RHEL 7 Enterprise Module Deployment
# ============================================================================
# Based on RedHatProducts repository documentation
# Module: localterraform.com/ag/instance/aws
# ============================================================================

# ============================================================================
# Instance Information Outputs
# ============================================================================

output "enterprise_instance_id" {
  description = "The unique identifier (ID) of the RHEL 7 EC2 instance"
  value       = module.rhel7_enterprise_instance.instance_id
}

output "enterprise_instance_arn" {
  description = "The Amazon Resource Name (ARN) of the RHEL 7 instance"
  value       = try(module.rhel7_enterprise_instance.instance_arn, "Not available from module")
}

output "enterprise_instance_state" {
  description = "The state of the instance (running, stopped, etc.)"
  value       = try(module.rhel7_enterprise_instance.instance_state, "Not available from module")
}

# ============================================================================
# Network Information Outputs
# ============================================================================

output "enterprise_public_ip" {
  description = "Public IP address of the RHEL 7 instance (for SSH and external access)"
  value       = module.rhel7_enterprise_instance.public_ip
}

output "enterprise_private_ip" {
  description = "Private IP address of the RHEL 7 instance within the VPC"
  value       = try(module.rhel7_enterprise_instance.private_ip, "Not available from module")
}

output "enterprise_public_dns" {
  description = "Public DNS name assigned to the instance"
  value       = try(module.rhel7_enterprise_instance.public_dns, "Not available from module")
}

output "enterprise_private_dns" {
  description = "Private DNS name assigned to the instance within the VPC"
  value       = try(module.rhel7_enterprise_instance.private_dns, "Not available from module")
}

# ============================================================================
# Availability and Placement Outputs
# ============================================================================

output "enterprise_availability_zone" {
  description = "The availability zone where the RHEL 7 instance is running"
  value       = try(module.rhel7_enterprise_instance.availability_zone, "Not available from module")
}

output "enterprise_subnet_id" {
  description = "The subnet ID where the instance is deployed"
  value       = try(module.rhel7_enterprise_instance.subnet_id, var.enterprise_subnet_id)
}

# ============================================================================
# AMI Information Outputs
# ============================================================================

output "enterprise_ami_id" {
  description = "The ID of the Red Hat Enterprise Linux 7 AMI used for the instance"
  value       = data.aws_ami.rhel7_enterprise.id
}

output "enterprise_ami_name" {
  description = "The name of the Red Hat Enterprise Linux 7 AMI"
  value       = data.aws_ami.rhel7_enterprise.name
}

output "enterprise_ami_description" {
  description = "Description of the RHEL 7 AMI"
  value       = data.aws_ami.rhel7_enterprise.description
}

output "enterprise_ami_creation_date" {
  description = "Creation date of the RHEL 7 AMI"
  value       = data.aws_ami.rhel7_enterprise.creation_date
}

# ============================================================================
# Security and Access Outputs
# ============================================================================

output "enterprise_security_groups" {
  description = "List of security group IDs attached to the instance"
  value       = try(module.rhel7_enterprise_instance.security_groups, var.enterprise_security_group_ids)
}

output "enterprise_key_name" {
  description = "The key pair name used for SSH access"
  value       = var.enterprise_key_name
}

output "enterprise_iam_instance_profile" {
  description = "IAM instance profile attached to the instance"
  value       = var.enterprise_iam_instance_profile != null ? var.enterprise_iam_instance_profile : "None"
}

# ============================================================================
# Storage Information Outputs
# ============================================================================

output "enterprise_root_volume_id" {
  description = "ID of the root EBS volume"
  value       = try(module.rhel7_enterprise_instance.root_volume_id, "Not available from module")
}

output "enterprise_root_volume_size" {
  description = "Size of the root volume in GB"
  value       = var.enterprise_root_volume_size
}

output "enterprise_root_volume_type" {
  description = "Type of the root EBS volume"
  value       = var.enterprise_root_volume_type
}

output "enterprise_root_volume_encrypted" {
  description = "Whether the root volume is encrypted"
  value       = var.enterprise_encrypt_root_volume
}

# ============================================================================
# Connection Information Outputs
# ============================================================================

output "enterprise_ssh_connection_command" {
  description = "SSH command to connect to the RHEL 7 instance"
  value       = "ssh -i ${var.enterprise_key_name}.pem ec2-user@${module.rhel7_enterprise_instance.public_ip}"
}

output "enterprise_ssh_connection_info" {
  description = "Detailed SSH connection information"
  value = {
    user        = "ec2-user"
    host        = module.rhel7_enterprise_instance.public_ip
    key_file    = "${var.enterprise_key_name}.pem"
    command     = "ssh -i ${var.enterprise_key_name}.pem ec2-user@${module.rhel7_enterprise_instance.public_ip}"
    description = "Connect using the ec2-user account with your private key"
  }
}

# ============================================================================
# Configuration Summary Output
# ============================================================================

output "enterprise_deployment_summary" {
  description = "Comprehensive summary of the RHEL 7 enterprise deployment"
  value = {
    # Instance details
    instance_id       = module.rhel7_enterprise_instance.instance_id
    instance_type     = var.enterprise_instance_type
    instance_name     = var.enterprise_instance_name
    
    # Network details
    public_ip         = module.rhel7_enterprise_instance.public_ip
    private_ip        = try(module.rhel7_enterprise_instance.private_ip, "N/A")
    availability_zone = try(module.rhel7_enterprise_instance.availability_zone, "N/A")
    
    # AMI details
    ami_id            = data.aws_ami.rhel7_enterprise.id
    ami_name          = data.aws_ami.rhel7_enterprise.name
    os_version        = "RHEL-7"
    
    # Storage details
    volume_type       = var.enterprise_root_volume_type
    volume_size       = "${var.enterprise_root_volume_size} GB"
    encrypted         = var.enterprise_encrypt_root_volume
    
    # Security details
    key_name          = var.enterprise_key_name
    iam_profile       = var.enterprise_iam_instance_profile != null ? var.enterprise_iam_instance_profile : "None"
    
    # Access details
    ssh_user          = "ec2-user"
    ssh_command       = "ssh -i ${var.enterprise_key_name}.pem ec2-user@${module.rhel7_enterprise_instance.public_ip}"
    
    # Deployment details
    deployment_type   = "Terraform Enterprise Module"
    module_source     = "localterraform.com/ag/instance/aws"
    managed_by        = "terraform-enterprise"
  }
}

# ============================================================================
# Cost Estimation Output
# ============================================================================

output "enterprise_estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (approximate, varies by region)"
  value = {
    instance_cost = "Varies by instance type and region (see AWS pricing)"
    storage_cost  = format("~$%.2f (for %d GB %s volume)", 
                           var.enterprise_root_volume_size * 0.08, 
                           var.enterprise_root_volume_size, 
                           var.enterprise_root_volume_type)
    note         = "Prices are estimates for US East region. Add data transfer, monitoring, and other service costs."
  }
}

# ============================================================================
# Resource Tags Output
# ============================================================================

output "enterprise_instance_tags" {
  description = "Tags applied to the RHEL 7 instance"
  value = merge(
    var.enterprise_common_tags,
    {
      Name           = var.enterprise_instance_name
      Environment    = var.environment
      Project        = var.project_name
      OS             = "RHEL-7"
      ManagedBy      = "terraform-enterprise"
      DeploymentType = "enterprise-module"
    }
  )
}

# ============================================================================
# Health Check URLs (if web server deployed)
# ============================================================================

output "enterprise_health_check_urls" {
  description = "Health check URLs (if HTTP/HTTPS services are configured)"
  value = {
    http_url  = "http://${module.rhel7_enterprise_instance.public_ip}"
    https_url = "https://${module.rhel7_enterprise_instance.public_ip}"
    note      = "These URLs will only work if web services are installed and security groups allow traffic"
  }
}

# ============================================================================
# Next Steps Output
# ============================================================================

output "enterprise_next_steps" {
  description = "Recommended next steps after deployment"
  value = {
    step_1 = "Connect via SSH: ssh -i ${var.enterprise_key_name}.pem ec2-user@${module.rhel7_enterprise_instance.public_ip}"
    step_2 = "Update system: sudo yum update -y"
    step_3 = "Install required packages: sudo yum install -y <package-names>"
    step_4 = "Configure application and services"
    step_5 = "Set up monitoring and backups"
    step_6 = "Review security group rules and restrict SSH access"
    step_7 = "Configure CloudWatch alarms for monitoring"
  }
}
