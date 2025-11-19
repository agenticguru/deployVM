# ============================================================================
# RedHat 7 EC2 Instance - Enterprise Module Outputs
# ============================================================================
# This file defines all outputs from the RedHat 7 EC2 instance deployment
# Outputs provide essential information for:
# - SSH access
# - Network connectivity
# - Resource identification
# - Integration with other infrastructure components
# - Monitoring and management
# ============================================================================

# ============================================================================
# VPC AND NETWORK OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC where resources are deployed"
  value       = aws_vpc.redhat_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.redhat_vpc.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.redhat_vpc.arn
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.redhat_igw.id
}

output "public_subnet_id" {
  description = "ID of the public subnet where the instance is deployed"
  value       = aws_subnet.redhat_public_subnet.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.redhat_public_subnet.cidr_block
}

output "public_subnet_availability_zone" {
  description = "Availability zone of the public subnet"
  value       = aws_subnet.redhat_public_subnet.availability_zone
}

output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.redhat_public_rt.id
}

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.redhat7_sg.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.redhat7_sg.name
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.redhat7_sg.arn
}

# ============================================================================
# EC2 INSTANCE OUTPUTS - PRIMARY
# ============================================================================

output "instance_id" {
  description = "ID of the RedHat 7 EC2 instance"
  value       = module.vm_example_rh7.instance_id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = module.vm_example_rh7.instance_arn
}

output "instance_state" {
  description = "Current state of the instance (running, stopped, etc.)"
  value       = module.vm_example_rh7.instance_state
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = var.instance_type
}

# ============================================================================
# NETWORK CONFIGURATION OUTPUTS
# ============================================================================

output "public_ip" {
  description = "Public IP address of the RedHat 7 instance (for SSH access)"
  value       = module.vm_example_rh7.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance within the VPC"
  value       = module.vm_example_rh7.private_ip
}

output "public_dns" {
  description = "Public DNS hostname of the instance"
  value       = module.vm_example_rh7.public_dns
}

output "private_dns" {
  description = "Private DNS hostname of the instance"
  value       = module.vm_example_rh7.private_dns
}

output "availability_zone" {
  description = "Availability zone where the instance is running"
  value       = module.vm_example_rh7.availability_zone
}

# ============================================================================
# ELASTIC IP OUTPUTS (If Created)
# ============================================================================

output "elastic_ip" {
  description = "Elastic IP address (static IP) if created"
  value       = var.create_elastic_ip ? aws_eip.redhat7_eip[0].public_ip : null
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = var.create_elastic_ip ? aws_eip.redhat7_eip[0].id : null
}

# ============================================================================
# AMI INFORMATION OUTPUTS
# ============================================================================

output "ami_id" {
  description = "ID of the RedHat 7 AMI used for the instance"
  value       = data.aws_ami.redhat7.id
}

output "ami_name" {
  description = "Name of the RedHat 7 AMI used"
  value       = data.aws_ami.redhat7.name
}

output "ami_description" {
  description = "Description of the RedHat 7 AMI"
  value       = data.aws_ami.redhat7.description
}

output "ami_creation_date" {
  description = "Creation date of the AMI"
  value       = data.aws_ami.redhat7.creation_date
}

output "ami_owner_id" {
  description = "AWS account ID of the AMI owner (Red Hat)"
  value       = data.aws_ami.redhat7.owner_id
}

# ============================================================================
# STORAGE OUTPUTS
# ============================================================================

output "root_volume_id" {
  description = "ID of the root EBS volume"
  value       = module.vm_example_rh7.root_volume_id
}

output "root_volume_type" {
  description = "Type of the root EBS volume (gp2, gp3, io1, io2)"
  value       = var.root_volume_type
}

output "root_volume_size" {
  description = "Size of the root volume in GB"
  value       = var.root_volume_size
}

output "root_volume_encrypted" {
  description = "Whether the root volume is encrypted"
  value       = var.encrypt_root_volume
}

# ============================================================================
# SSH CONNECTION INFORMATION
# ============================================================================

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.vm_example_rh7.public_ip}"
}

output "ssh_connection_via_eip" {
  description = "SSH command using Elastic IP (if created)"
  value       = var.create_elastic_ip ? "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.redhat7_eip[0].public_ip}" : "Elastic IP not created"
}

output "ssh_user" {
  description = "Default SSH user for RedHat 7"
  value       = "ec2-user"
}

output "ssh_key_name" {
  description = "Name of the SSH key pair used"
  value       = var.key_name
}

# ============================================================================
# MONITORING OUTPUTS
# ============================================================================

output "cloudwatch_log_group" {
  description = "CloudWatch log group for instance logs"
  value       = "/aws/ec2/${var.project_name}-${var.environment}-redhat7"
}

output "cpu_alarm_arn" {
  description = "ARN of the CPU utilization CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.cpu_alarm[0].arn : null
}

output "status_check_alarm_arn" {
  description = "ARN of the status check CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.status_check_alarm[0].arn : null
}

# ============================================================================
# TAGS AND METADATA OUTPUTS
# ============================================================================

output "instance_tags" {
  description = "All tags applied to the instance"
  value       = module.vm_example_rh7.tags
}

output "environment" {
  description = "Environment where the instance is deployed"
  value       = var.environment
}

output "project_name" {
  description = "Project name for the deployment"
  value       = var.project_name
}

# ============================================================================
# SECURITY OUTPUTS
# ============================================================================

output "security_group_rules" {
  description = "Summary of security group rules"
  value = {
    ssh_allowed_cidrs = var.allowed_ssh_cidrs
    http_enabled      = var.enable_http_access
    https_enabled     = var.enable_https_access
  }
}

output "encryption_status" {
  description = "Encryption status of resources"
  value = {
    root_volume_encrypted = var.encrypt_root_volume
    ebs_encryption        = "AWS-managed keys (AES-256)"
  }
}

# ============================================================================
# DEPLOYMENT SUMMARY OUTPUT
# ============================================================================

output "deployment_summary" {
  description = "Comprehensive summary of the deployed RedHat 7 infrastructure"
  value = {
    # Instance Information
    instance_id   = module.vm_example_rh7.instance_id
    instance_type = var.instance_type
    instance_name = "${var.project_name}-${var.environment}-redhat7"
    
    # Network Information
    public_ip           = module.vm_example_rh7.public_ip
    private_ip          = module.vm_example_rh7.private_ip
    availability_zone   = module.vm_example_rh7.availability_zone
    elastic_ip          = var.create_elastic_ip ? aws_eip.redhat7_eip[0].public_ip : "Not created"
    
    # VPC Information
    vpc_id              = aws_vpc.redhat_vpc.id
    subnet_id           = aws_subnet.redhat_public_subnet.id
    security_group_id   = aws_security_group.redhat7_sg.id
    
    # AMI Information
    ami_id              = data.aws_ami.redhat7.id
    ami_name            = data.aws_ami.redhat7.name
    os_version          = "RHEL-7"
    
    # Storage Information
    root_volume_type    = var.root_volume_type
    root_volume_size_gb = var.root_volume_size
    encryption_enabled  = var.encrypt_root_volume
    
    # Access Information
    ssh_command         = "ssh -i ${var.key_name}.pem ec2-user@${module.vm_example_rh7.public_ip}"
    ssh_user            = "ec2-user"
    key_pair_name       = var.key_name
    
    # Deployment Metadata
    region              = var.aws_region
    environment         = var.environment
    project             = var.project_name
    deployment_method   = "Terraform Enterprise Module"
    module_source       = "localterraform.com/ag/instance/aws"
    module_version      = "~> 3.0"
  }
}

# ============================================================================
# COST ESTIMATION OUTPUT
# ============================================================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (approximate USD)"
  value = {
    instance_type = var.instance_type
    storage_gb    = var.root_volume_size
    note          = "Costs vary by region and usage. Use AWS Cost Calculator for accurate estimates."
    pricing_url   = "https://calculator.aws/#/"
  }
}

# ============================================================================
# QUICK REFERENCE OUTPUT
# ============================================================================

output "quick_reference" {
  description = "Quick reference information for common tasks"
  value = {
    connect_ssh       = "ssh -i ${var.key_name}.pem ec2-user@${module.vm_example_rh7.public_ip}"
    view_instance     = "aws ec2 describe-instances --instance-ids ${module.vm_example_rh7.instance_id}"
    start_instance    = "aws ec2 start-instances --instance-ids ${module.vm_example_rh7.instance_id}"
    stop_instance     = "aws ec2 stop-instances --instance-ids ${module.vm_example_rh7.instance_id}"
    reboot_instance   = "aws ec2 reboot-instances --instance-ids ${module.vm_example_rh7.instance_id}"
    view_console      = "https://console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#Instances:instanceId=${module.vm_example_rh7.instance_id}"
    check_status      = "aws ec2 describe-instance-status --instance-ids ${module.vm_example_rh7.instance_id}"
  }
}

# ============================================================================
# OPERATIONAL OUTPUTS
# ============================================================================

output "management_endpoints" {
  description = "Management and monitoring endpoints"
  value = {
    aws_console           = "https://console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}"
    cloudwatch_metrics    = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2:graph=~();query=~'{AWS/EC2,InstanceId}~'${module.vm_example_rh7.instance_id}"
    cloudwatch_logs       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/$252Faws$252Fec2$252F${var.project_name}-${var.environment}-redhat7"
    systems_manager       = "https://console.aws.amazon.com/systems-manager/managed-instances/${module.vm_example_rh7.instance_id}?region=${var.aws_region}"
  }
}

# ============================================================================
# TROUBLESHOOTING OUTPUTS
# ============================================================================

output "troubleshooting_info" {
  description = "Information useful for troubleshooting"
  value = {
    instance_id         = module.vm_example_rh7.instance_id
    security_group_id   = aws_security_group.redhat7_sg.id
    subnet_id           = aws_subnet.redhat_public_subnet.id
    route_table_id      = aws_route_table.redhat_public_rt.id
    internet_gateway_id = aws_internet_gateway.redhat_igw.id
    
    common_checks = {
      verify_sg_rules    = "aws ec2 describe-security-groups --group-ids ${aws_security_group.redhat7_sg.id}"
      verify_route_table = "aws ec2 describe-route-tables --route-table-ids ${aws_route_table.redhat_public_rt.id}"
      check_nacl         = "aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=${aws_subnet.redhat_public_subnet.id}"
      get_system_log     = "aws ec2 get-console-output --instance-id ${module.vm_example_rh7.instance_id}"
    }
  }
}

# ============================================================================
# END OF OUTPUTS
# ============================================================================
