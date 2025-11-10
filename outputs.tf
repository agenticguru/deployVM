# VPC and Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.redhat_sg.id
}

# EC2 Instance Outputs (Enhanced Instance)
output "instance_id" {
  description = "ID of the RedHat 7 EC2 instance"
  value       = aws_instance.redhat7_enhanced.id
}

output "instance_public_ip" {
  description = "Public IP address of the RedHat 7 instance"
  value       = aws_instance.redhat7_enhanced.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the RedHat 7 instance"
  value       = aws_instance.redhat7_enhanced.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the RedHat 7 instance"
  value       = aws_instance.redhat7_enhanced.public_dns
}

output "instance_availability_zone" {
  description = "Availability zone where the instance is running"
  value       = aws_instance.redhat7_enhanced.availability_zone
}

output "instance_state" {
  description = "Current state of the instance"
  value       = aws_instance.redhat7_enhanced.instance_state
}

# AMI Information
output "ami_id" {
  description = "ID of the RedHat 7 AMI used"
  value       = data.aws_ami.redhat7.id
}

output "ami_name" {
  description = "Name of the RedHat 7 AMI used"
  value       = data.aws_ami.redhat7.name
}

# SSH Connection Information
output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.redhat7_enhanced.public_ip}"
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployed resources"
  value = {
    project_name   = var.project_name
    environment    = var.environment
    region         = var.aws_region
    instance_type  = var.instance_type
    instance_id    = aws_instance.redhat7_enhanced.id
    public_ip      = aws_instance.redhat7_enhanced.public_ip
    vpc_id         = aws_vpc.main.id
    security_group = aws_security_group.redhat_sg.id
  }
}