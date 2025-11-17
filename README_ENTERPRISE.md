# RHEL 7 EC2 Instance Provisioning with Terraform Enterprise Module

## Overview

This directory contains Terraform code for provisioning **Red Hat Enterprise Linux 7 (RHEL 7)** EC2 instances on AWS using the internal Terraform Enterprise module hosted at `localterraform.com/ag/instance/aws`.

The configuration is based on parameters and best practices documented in the **RedHatProducts** repository and provides enterprise-grade deployment capabilities with comprehensive security, storage, and networking options.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Parameters Reference](#parameters-reference)
6. [Usage Examples](#usage-examples)
7. [Outputs](#outputs)
8. [Security Best Practices](#security-best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Cost Estimation](#cost-estimation)

---

## Prerequisites

### Required Tools

- **Terraform** >= 1.0
- **AWS CLI** configured with valid credentials
- **Access to Terraform Enterprise** module registry at `localterraform.com/ag/instance/aws`

### AWS Requirements

1. **AWS Account** with EC2 permissions
2. **EC2 Key Pair** created in target region
3. **VPC Infrastructure** (subnet, security groups) - can be created automatically or provided
4. **IAM Credentials** with following permissions:
   - `ec2:RunInstances`
   - `ec2:DescribeInstances`
   - `ec2:DescribeImages`
   - `ec2:DescribeKeyPairs`
   - `ec2:CreateTags`
   - `ec2:TerminateInstances`

### Terraform Enterprise Access

Ensure you have access to the internal Terraform Enterprise module:
```bash
# Verify access (if authentication is required)
terraform login localterraform.com
```

---

## Architecture

### Deployment Components

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Cloud (Region)                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                    │  │
│  │                                                          │  │
│  │  ┌───────────────────────────────────────────────────┐  │  │
│  │  │        Public Subnet (10.0.1.0/24)                │  │  │
│  │  │                                                    │  │  │
│  │  │  ┌──────────────────────────────────────────┐     │  │  │
│  │  │  │    RHEL 7 EC2 Instance                   │     │  │  │
│  │  │  │                                           │     │  │  │
│  │  │  │  • Instance Type: t3.micro (default)     │     │  │  │
│  │  │  │  • OS: Red Hat Enterprise Linux 7        │     │  │  │
│  │  │  │  • Public IP: Auto-assigned              │     │  │  │
│  │  │  │  • Security Group: SSH/HTTP/HTTPS        │     │  │  │
│  │  │  │  • Storage: 20GB gp3 (encrypted)         │     │  │  │
│  │  │  │                                           │     │  │  │
│  │  │  │  Deployed via:                           │     │  │  │
│  │  │  │  localterraform.com/ag/instance/aws      │     │  │  │
│  │  │  └──────────────────────────────────────────┘     │  │  │
│  │  │                                                    │  │  │
│  │  └───────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  Internet Gateway                                             │
│  └──────────────────────────────────────────────────────────┘
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Module Architecture

The deployment uses the internal Terraform Enterprise module which automatically handles:
- **AMI Selection**: Latest official RHEL 7 AMI from Red Hat (owner ID: 309956199498)
- **Networking**: VPC, subnet, and security group configuration
- **Storage**: EBS volume provisioning with encryption options
- **Security**: IAM roles, key pairs, and security group rules
- **Tagging**: Comprehensive resource tagging for management

---

## Quick Start

### 1. Create Key Pair

First, create an EC2 key pair in your target AWS region:

```bash
# Create new key pair
aws ec2 create-key-pair \
  --key-name my-rhel7-key \
  --query 'KeyMaterial' \
  --output text > my-rhel7-key.pem

# Set proper permissions
chmod 400 my-rhel7-key.pem
```

### 2. Configure Variables

Copy the example configuration and customize:

```bash
cp terraform.tfvars.enterprise.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Basic configuration
enterprise_instance_type = "t3.micro"
enterprise_key_name      = "my-rhel7-key"
enterprise_instance_name = "my-app-rhel7"

# Project information
project_name = "my-project"
environment  = "production"
aws_region   = "us-east-1"
```

### 3. Initialize Terraform

```bash
terraform init
```

This will download the required providers and connect to the Terraform Enterprise module registry.

### 4. Review Deployment Plan

```bash
terraform plan
```

Review the planned changes carefully before applying.

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 6. Access Your Instance

After deployment completes, get the connection information:

```bash
# Get SSH connection command
terraform output enterprise_ssh_connection_command

# Connect to instance
ssh -i my-rhel7-key.pem ec2-user@<PUBLIC_IP>
```

---

## Configuration

### File Structure

```
deployVM/
├── rhel7_enterprise.tf              # Main module configuration
├── variables_enterprise.tf          # Variable definitions
├── outputs_enterprise.tf            # Output definitions
├── terraform.tfvars.enterprise.example  # Example configuration
├── terraform.tfvars                 # Your actual configuration (not in git)
└── README_ENTERPRISE.md             # This documentation
```

### Key Configuration Files

#### rhel7_enterprise.tf
Main Terraform configuration that:
- Declares the Terraform Enterprise module
- Configures RHEL 7 instance parameters
- Sets up networking and storage
- Applies resource tags

#### variables_enterprise.tf
Defines all configurable parameters with:
- Type constraints
- Default values
- Validation rules
- Documentation

#### outputs_enterprise.tf
Defines output values including:
- Instance IDs and IP addresses
- AMI information
- SSH connection details
- Deployment summary

---

## Parameters Reference

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `enterprise_instance_type` | string | EC2 instance type | `"t3.micro"` |
| `enterprise_key_name` | string | SSH key pair name | `"my-rhel7-key"` |

### Core Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enterprise_instance_name` | string | `"redhat7-enterprise-instance"` | Instance name tag |
| `enterprise_subnet_id` | string | `null` | Target subnet ID |
| `enterprise_security_group_ids` | list(string) | `null` | Security group IDs |
| `enterprise_availability_zone` | string | `null` | Availability zone |

### Storage Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enterprise_root_volume_type` | string | `"gp3"` | EBS volume type (gp2/gp3/io1/io2) |
| `enterprise_root_volume_size` | number | `20` | Volume size in GB (10-1000) |
| `enterprise_encrypt_root_volume` | bool | `true` | Enable volume encryption |

### Advanced Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enterprise_user_data` | string | See file | Initialization script |
| `enterprise_iam_instance_profile` | string | `null` | IAM role for instance |
| `enterprise_enable_monitoring` | bool | `false` | Detailed CloudWatch monitoring |
| `enterprise_ebs_optimized` | bool | `true` | EBS optimization |
| `enterprise_disable_api_termination` | bool | `false` | Termination protection |

### Complete Parameter Documentation

See [variables_enterprise.tf](./variables_enterprise.tf) for complete parameter documentation with validation rules and usage guidance.

---

## Usage Examples

### Example 1: Basic Development Instance

Minimal configuration for development/testing:

```hcl
# terraform.tfvars
enterprise_instance_type = "t3.micro"
enterprise_key_name      = "dev-key"
enterprise_instance_name = "dev-rhel7-test"
project_name             = "development"
environment              = "dev"
```

### Example 2: Production Instance

Recommended configuration for production workloads:

```hcl
# terraform.tfvars
enterprise_instance_type        = "t3.medium"
enterprise_key_name             = "prod-key"
enterprise_instance_name        = "prod-app-rhel7"
enterprise_root_volume_type     = "gp3"
enterprise_root_volume_size     = 50
enterprise_encrypt_root_volume  = true
enterprise_enable_monitoring    = true
enterprise_disable_api_termination = true

project_name = "production"
environment  = "prod"

enterprise_common_tags = {
  Environment = "production"
  Project     = "my-app"
  Owner       = "platform-team"
  CostCenter  = "engineering"
  Compliance  = "pci-dss"
  Backup      = "daily"
}
```

### Example 3: High-Performance Instance

Configuration for compute or memory-intensive workloads:

```hcl
# terraform.tfvars
enterprise_instance_type        = "m5.xlarge"
enterprise_key_name             = "prod-key"
enterprise_instance_name        = "prod-db-rhel7"
enterprise_root_volume_type     = "io2"
enterprise_root_volume_size     = 200
enterprise_encrypt_root_volume  = true
enterprise_enable_monitoring    = true
enterprise_ebs_optimized        = true
enterprise_disable_api_termination = true

# Custom user data for database setup
enterprise_user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y postgresql-server postgresql-contrib
  postgresql-setup initdb
  systemctl enable postgresql
  systemctl start postgresql
EOF

project_name = "production"
environment  = "prod"
```

### Example 4: Instance with Existing Infrastructure

Use existing VPC, subnet, and security groups:

```hcl
# terraform.tfvars
enterprise_instance_type       = "t3.medium"
enterprise_key_name            = "prod-key"
enterprise_instance_name       = "app-rhel7"
enterprise_subnet_id           = "subnet-0abc123def456789"
enterprise_security_group_ids  = ["sg-0123456789abcdef0"]
enterprise_availability_zone   = "us-east-1a"
enterprise_associate_public_ip = false  # Private subnet

project_name = "production"
environment  = "prod"
```

---

## Outputs

After deployment, the following outputs are available:

### Instance Information

```bash
# Get instance ID
terraform output enterprise_instance_id

# Get public IP
terraform output enterprise_public_ip

# Get private IP
terraform output enterprise_private_ip
```

### Connection Information

```bash
# Get SSH command
terraform output enterprise_ssh_connection_command

# Get detailed connection info
terraform output enterprise_ssh_connection_info
```

### Complete Deployment Summary

```bash
# Get full deployment details
terraform output enterprise_deployment_summary
```

### Available Outputs

| Output | Description |
|--------|-------------|
| `enterprise_instance_id` | EC2 instance ID |
| `enterprise_public_ip` | Public IP address |
| `enterprise_private_ip` | Private IP address |
| `enterprise_availability_zone` | Availability zone |
| `enterprise_ami_id` | RHEL 7 AMI ID used |
| `enterprise_ami_name` | RHEL 7 AMI name |
| `enterprise_ssh_connection_command` | Ready-to-use SSH command |
| `enterprise_deployment_summary` | Complete deployment details |
| `enterprise_next_steps` | Post-deployment recommendations |

---

## Security Best Practices

### 1. SSH Key Management

```bash
# Generate secure key pair
aws ec2 create-key-pair --key-name prod-rhel7-key \
  --query 'KeyMaterial' --output text > prod-rhel7-key.pem

# Set restrictive permissions
chmod 400 prod-rhel7-key.pem

# Never commit private keys to version control
echo "*.pem" >> .gitignore
```

### 2. Restrict SSH Access

**DON'T** use `0.0.0.0/0` in production:

```hcl
# BAD - Allows SSH from anywhere
allowed_ssh_cidrs = ["0.0.0.0/0"]

# GOOD - Restrict to specific IPs/ranges
allowed_ssh_cidrs = [
  "203.0.113.0/24",    # Office network
  "198.51.100.50/32"   # Specific admin IP
]
```

### 3. Enable Encryption

Always enable encryption for production workloads:

```hcl
enterprise_encrypt_root_volume = true
```

### 4. Use IAM Roles

Instead of storing AWS credentials on instances:

```hcl
enterprise_iam_instance_profile = "app-server-role"
```

### 5. Enable Termination Protection

Prevent accidental deletion of production instances:

```hcl
enterprise_disable_api_termination = true
```

### 6. Implement Network Segmentation

Deploy sensitive workloads in private subnets:

```hcl
enterprise_subnet_id           = "subnet-private-xxxxx"
enterprise_associate_public_ip = false
```

### 7. Regular Updates

Configure automatic security updates:

```hcl
enterprise_user_data = <<-EOF
  #!/bin/bash
  yum install -y yum-cron
  systemctl enable yum-cron
  systemctl start yum-cron
EOF
```

### 8. Monitoring and Logging

Enable detailed monitoring for production:

```hcl
enterprise_enable_monitoring = true
```

---

## Troubleshooting

### Module Not Found

**Error**: "Module not found: localterraform.com/ag/instance/aws"

**Solutions**:
1. Verify Terraform Enterprise access
2. Authenticate: `terraform login localterraform.com`
3. Check module version constraint
4. Run: `terraform init -upgrade`

### Key Pair Not Found

**Error**: "InvalidKeyPair.NotFound: The key pair 'xxx' does not exist"

**Solutions**:
```bash
# Check if key exists
aws ec2 describe-key-pairs --key-names your-key-name

# Create new key
aws ec2 create-key-pair --key-name your-key-name \
  --query 'KeyMaterial' --output text > your-key-name.pem
chmod 400 your-key-name.pem
```

### AMI Not Available

**Error**: "InvalidAMIID.NotFound" or no AMI returned

**Solutions**:
```bash
# List available RHEL 7 AMIs
aws ec2 describe-images \
  --owners 309956199498 \
  --filters "Name=name,Values=RHEL-7.*-x86_64-*" \
  --query 'Images[*].[Name,ImageId,CreationDate]' \
  --output table
```

### Insufficient Permissions

**Error**: "UnauthorizedOperation: You are not authorized"

**Solution**: Ensure your IAM user/role has these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeKeyPairs",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:CreateTags",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

### Cannot Connect via SSH

**Symptoms**: Connection timeout or refused

**Solutions**:

1. **Check Security Group**:
```bash
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

2. **Verify Instance is Running**:
```bash
aws ec2 describe-instances --instance-ids i-xxxxx
```

3. **Check Your Public IP**:
```bash
curl -4 ifconfig.me
```

4. **Test Connectivity**:
```bash
# Test port 22
nc -zv <PUBLIC_IP> 22

# Try verbose SSH
ssh -vvv -i key.pem ec2-user@<PUBLIC_IP>
```

### Instance Fails to Start

**Possible Causes**:
1. Insufficient capacity in AZ
2. Instance limits exceeded
3. Invalid subnet configuration

**Solutions**:
```bash
# Try different AZ
enterprise_availability_zone = "us-east-1b"

# Check service limits
aws service-quotas list-service-quotas \
  --service-code ec2 \
  --query 'Quotas[?QuotaName==`Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances`]'
```

---

## Cost Estimation

### Instance Costs (US East Region)

| Instance Type | vCPU | Memory | Hourly | Monthly |
|---------------|------|--------|--------|---------|
| t3.micro | 2 | 1 GB | $0.0104 | ~$8 |
| t3.small | 2 | 2 GB | $0.0208 | ~$15 |
| t3.medium | 2 | 4 GB | $0.0416 | ~$30 |
| m5.large | 2 | 8 GB | $0.096 | ~$70 |
| m5.xlarge | 4 | 16 GB | $0.192 | ~$140 |
| c5.large | 2 | 4 GB | $0.085 | ~$62 |
| r5.large | 2 | 16 GB | $0.126 | ~$91 |

### Storage Costs

| Volume Type | Cost per GB/month | Example (50 GB) |
|-------------|-------------------|-----------------|
| gp2 | $0.10 | $5.00 |
| gp3 | $0.08 | $4.00 |
| io1 | $0.125 + $0.065/IOPS | Varies |
| io2 | $0.125 + $0.065/IOPS | Varies |

### Additional Costs

- **Data Transfer**: $0.09/GB (first 10TB/month outbound)
- **CloudWatch**: Detailed monitoring ~$3/month per instance
- **EBS Snapshots**: $0.05/GB/month
- **Elastic IP**: $3.65/month if not associated with running instance

### Example Total Cost

**Development Instance (t3.micro + 20GB gp3)**:
- Instance: $8/month
- Storage: $1.60/month
- **Total: ~$10/month**

**Production Instance (t3.medium + 50GB gp3 + monitoring)**:
- Instance: $30/month
- Storage: $4/month
- Monitoring: $3/month
- **Total: ~$37/month**

**High-Performance Instance (m5.xlarge + 200GB io2)**:
- Instance: $140/month
- Storage: $25/month + IOPS charges
- Monitoring: $3/month
- **Total: ~$170+/month**

> **Note**: RHEL AMIs include Red Hat subscription costs in the hourly rate. Prices vary by region.

---

## Module Documentation Reference

### Terraform Enterprise Module

- **Source**: `localterraform.com/ag/instance/aws`
- **Version**: `~> 1.0`
- **Type**: AWS EC2 Instance Provisioning

### RedHatProducts Repository

Parameters are based on the RedHatProducts repository documentation:
- Location: `/sandbox/RedHatProducts/README.md`
- Module documentation: `/sandbox/RedHatProducts/RedHatProducts/modules/redhat7/`

### Related Documentation

- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [RHEL 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Pricing Calculator](https://calculator.aws/)

---

## Quick Reference Commands

### Terraform Operations

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# View outputs
terraform output

# Show current state
terraform show

# Refresh state
terraform refresh
```

### AWS CLI Verification

```bash
# List key pairs
aws ec2 describe-key-pairs

# List AMIs
aws ec2 describe-images --owners 309956199498 \
  --filters "Name=name,Values=RHEL-7.*"

# List running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# List subnets
aws ec2 describe-subnets

# List security groups
aws ec2 describe-security-groups
```

---

## Support and Contributing

### Getting Help

1. Review this documentation
2. Check [Troubleshooting](#troubleshooting) section
3. Verify RedHatProducts repository documentation
4. Contact infrastructure team

### Reporting Issues

When reporting issues, include:
- Terraform version (`terraform version`)
- Error messages (full output)
- Configuration files (sanitized)
- AWS region
- Instance type

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

---

## License

Internal use only. See organizational license agreements for RHEL and AWS usage.

---

## Changelog

### Version 1.0.0 (Initial Release)
- Initial implementation using Terraform Enterprise module
- Support for RHEL 7 EC2 instances
- Comprehensive parameter configuration
- Security best practices implementation
- Complete documentation

---

**Last Updated**: 2024
**Maintained By**: Infrastructure Team
**Repository**: deployVM
