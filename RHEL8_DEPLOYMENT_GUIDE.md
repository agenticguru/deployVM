# RedHat 8 VM Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying RedHat Enterprise Linux 8 VMs using the internal Terraform module from `localterraform.com/ag/instance/aws`.

## Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Module Details](#module-details)
4. [Quick Start](#quick-start)
5. [Configuration Parameters](#configuration-parameters)
6. [Deployment Steps](#deployment-steps)
7. [Post-Deployment](#post-deployment)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Architecture

The deployment creates a production-ready RedHat 8 VM with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Region                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │      Public Subnet (10.0.1.0/24)                │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │   RHEL 8 EC2 Instance                     │  │  │  │
│  │  │  │   • Public IP (Internet Access)           │  │  │  │
│  │  │  │   • Private IP (VPC Communication)        │  │  │  │
│  │  │  │   • Security Groups (SSH/HTTP/HTTPS)      │  │  │  │
│  │  │  │   • Encrypted EBS Volume                  │  │  │  │
│  │  │  │   • CloudWatch Monitoring                 │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                          │                             │  │
│  │  ┌───────────────────────▼──────────────────────────┐  │  │
│  │  │          Internet Gateway                         │  │  │
│  │  └───────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

✅ **Enterprise-Grade Configuration**: Production-ready with security best practices  
✅ **Automatic AMI Selection**: Uses latest official RHEL 8 AMI from Red Hat  
✅ **Full VPC Integration**: Complete network isolation and security  
✅ **Encrypted Storage**: EBS volume encryption at rest  
✅ **Comprehensive Tagging**: Cost allocation, compliance, and resource management  
✅ **High Availability Ready**: Multi-AZ deployment capability  

## Prerequisites

### 1. Required Software

- **Terraform**: Version >= 1.0 (Recommended: Latest stable)
  ```bash
  terraform --version
  ```

- **AWS CLI**: For AWS resource management (Optional but recommended)
  ```bash
  aws --version
  ```

### 2. AWS Account Requirements

- **Active AWS Account** with appropriate permissions
- **IAM Permissions**: EC2, VPC, and resource tagging permissions
- **Service Quotas**: Sufficient EC2 instance limits in target region
- **AWS Marketplace**: RHEL subscription (automatically handled by AWS)

### 3. Required AWS Resources

The following resources must exist or will be created:

#### Must Exist Before Deployment:
- ✅ **EC2 Key Pair**: For SSH access to instances
  ```bash
  # Create key pair
  aws ec2 create-key-pair --key-name my-rhel8-key \
    --query 'KeyMaterial' --output text > my-rhel8-key.pem
  chmod 400 my-rhel8-key.pem
  ```

#### Created Automatically by Terraform:
- VPC and networking components
- Security groups
- Subnets and route tables
- Internet gateway

### 4. Authentication Setup

Configure AWS credentials using one of these methods:

**Option 1: Environment Variables (Recommended)**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option 2: AWS Credentials File**
```bash
aws configure
```

**Option 3: IAM Role** (for EC2/ECS/Lambda execution)

## Module Details

### Module Source

The deployment uses the internal Terraform registry module:

```hcl
module "redhat8_production" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"
  
  # ... configuration parameters
}
```

### Required Parameters

All 10 parameters are **REQUIRED** by the module (no defaults):

| Parameter | Type | Description |
|-----------|------|-------------|
| `instance_type` | string | EC2 instance type (e.g., t3.medium) |
| `key_name` | string | SSH key pair name |
| `subnet_id` | string | VPC subnet ID for instance placement |
| `security_group_ids` | list(string) | Security group IDs for network access |
| `availability_zone` | string | AWS availability zone |
| `instance_name` | string | Name tag for the instance |
| `root_volume_type` | string | EBS volume type (gp2, gp3, io1, io2) |
| `root_volume_size` | number | Root volume size in GB |
| `encrypt_root_volume` | bool | Enable volume encryption |
| `tags` | map(string) | Additional resource tags |

### Module Outputs

The module provides 4 outputs:

| Output | Description |
|--------|-------------|
| `instance_id` | EC2 instance identifier |
| `public_ip` | Public IP address |
| `private_ip` | Private IP address within VPC |
| `availability_zone` | Instance availability zone |

## Quick Start

### 1. Clone/Navigate to Repository

```bash
cd /projects/sandbox/deployVM
```

### 2. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.rhel8.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Minimum Required Configuration:**
```hcl
aws_region      = "us-east-1"
project_name    = "my-project"
environment     = "prod"
key_name        = "my-rhel8-key"
instance_type   = "t3.medium"
```

### 3. Initialize Terraform

```bash
terraform init
```

This will:
- Download AWS provider
- Initialize the internal module from localterraform.com
- Set up backend configuration

### 4. Review Deployment Plan

```bash
terraform plan
```

Expected resources to be created:
- 1 VPC
- 1 Internet Gateway
- 1 Public Subnet
- 1 Route Table + Association
- 1 Security Group
- 1 EC2 Instance (RHEL 8)

### 5. Deploy Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

Deployment time: ~2-3 minutes

### 6. Get Deployment Information

```bash
# Get all outputs
terraform output

# Get specific output
terraform output rhel8_public_ip
terraform output rhel8_ssh_command
```

### 7. Connect to Instance

```bash
# Using the SSH command output
ssh -i my-rhel8-key.pem ec2-user@<PUBLIC_IP>

# Or use terraform output directly
$(terraform output -raw rhel8_ssh_command)
```

## Configuration Parameters

### Instance Sizing Guide

| Use Case | Instance Type | vCPUs | Memory | Recommended For |
|----------|--------------|-------|--------|-----------------|
| Development | t3.micro | 2 | 1 GB | Testing, learning |
| Small Apps | t3.small | 2 | 2 GB | Low-traffic websites |
| Standard | t3.medium | 2 | 4 GB | Web servers, APIs |
| Production | m5.large | 2 | 8 GB | Business applications |
| High-Performance | m5.xlarge | 4 | 16 GB | Databases, analytics |

### Storage Configuration

**Volume Types:**

| Type | Performance | Use Case | Cost |
|------|-------------|----------|------|
| gp3 | 3,000 IOPS baseline | General purpose (RECOMMENDED) | $$ |
| gp2 | 3 IOPS/GB | Legacy workloads | $ |
| io1 | Up to 64,000 IOPS | High-performance databases | $$$ |
| io2 | Up to 64,000 IOPS + durability | Mission-critical | $$$$ |

**Volume Sizing:**

| Application Type | Recommended Size |
|-----------------|------------------|
| RHEL OS Only | 10-20 GB |
| Web Server | 20-50 GB |
| Application Server | 50-100 GB |
| Database Server | 100-500 GB |
| Data-Intensive | 500+ GB |

### Security Configuration

**SSH Access Best Practices:**

```hcl
# ❌ NOT RECOMMENDED - Open to world
allowed_ssh_cidrs = ["0.0.0.0/0"]

# ✅ RECOMMENDED - Specific IP ranges
allowed_ssh_cidrs = [
  "203.0.113.0/24",      # Office network
  "198.51.100.50/32"     # VPN gateway
]
```

**Encryption Settings:**

```hcl
# ✅ PRODUCTION - Always encrypt
encrypt_root_volume = true

# ⚠️ DEVELOPMENT ONLY - Can disable for cost
encrypt_root_volume = false
```

## Deployment Steps

### Step-by-Step Production Deployment

#### 1. Preparation Phase

```bash
# Set working directory
cd /projects/sandbox/deployVM

# Verify prerequisites
terraform --version    # Check Terraform installed
aws sts get-caller-identity  # Verify AWS credentials

# Create SSH key if needed
aws ec2 create-key-pair --key-name production-rhel8-key \
  --query 'KeyMaterial' --output text > ~/.ssh/production-rhel8-key.pem
chmod 400 ~/.ssh/production-rhel8-key.pem
```

#### 2. Configuration Phase

```bash
# Create configuration file
cat > terraform.tfvars <<EOF
aws_region      = "us-east-1"
project_name    = "enterprise-app"
environment     = "prod"
instance_type   = "t3.medium"
key_name        = "production-rhel8-key"

# Security - Replace with your IP
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Storage
root_volume_type    = "gp3"
root_volume_size    = 50
encrypt_root_volume = true
EOF
```

#### 3. Validation Phase

```bash
# Initialize and validate
terraform init
terraform validate
terraform fmt

# Review plan
terraform plan -out=rhel8.tfplan

# Review planned changes carefully
```

#### 4. Deployment Phase

```bash
# Apply configuration
terraform apply rhel8.tfplan

# Save outputs
terraform output -json > deployment-outputs.json
```

#### 5. Verification Phase

```bash
# Get instance information
INSTANCE_IP=$(terraform output -raw rhel8_public_ip)
INSTANCE_ID=$(terraform output -raw rhel8_instance_id)

# Wait for instance to be ready
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Test SSH connectivity
ssh -i ~/.ssh/production-rhel8-key.pem ec2-user@$INSTANCE_IP "echo 'Connection successful'"

# Verify RHEL version
ssh -i ~/.ssh/production-rhel8-key.pem ec2-user@$INSTANCE_IP "cat /etc/redhat-release"
```

## Post-Deployment

### Initial System Configuration

Once connected to the instance:

```bash
# 1. Update system packages
sudo yum update -y

# 2. Install essential tools
sudo yum install -y \
  htop \
  wget \
  curl \
  vim \
  git \
  net-tools \
  sysstat

# 3. Configure system monitoring
sudo yum install -y amazon-cloudwatch-agent

# 4. Set up automatic updates (optional)
sudo yum install -y yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# 5. Verify encryption
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,ENCRYPTED
```

### Configure CloudWatch Monitoring

```bash
# Create CloudWatch config
sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "metrics": {
    "namespace": "RedHat8/Monitoring",
    "metrics_collected": {
      "cpu": {"measurement": [{"name": "cpu_usage_idle"}]},
      "disk": {"measurement": [{"name": "used_percent"}]},
      "mem": {"measurement": [{"name": "mem_used_percent"}]}
    }
  }
}
EOF

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

### Security Hardening

```bash
# 1. Update security packages
sudo yum update -y --security

# 2. Configure firewall
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# 3. Configure fail2ban for SSH protection
sudo yum install -y epel-release
sudo yum install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 4. Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Monitoring & Maintenance

### CloudWatch Metrics

Monitor these key metrics in AWS CloudWatch:

- **CPU Utilization**: Set alarm at >80% for 5 minutes
- **Disk Usage**: Set alarm at >85%
- **Memory Usage**: Set alarm at >90%
- **Network Traffic**: Monitor for unusual patterns
- **Status Checks**: System and instance reachability

### Create CloudWatch Alarms

```bash
# CPU Utilization Alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rhel8-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID
```

### Backup Strategy

**Option 1: AWS Backup**
```bash
# Enable AWS Backup via console or CLI
aws backup create-backup-plan --backup-plan file://backup-plan.json
```

**Option 2: EBS Snapshots**
```bash
# Manual snapshot
aws ec2 create-snapshot \
  --volume-id $(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text) \
  --description "RHEL8 manual backup $(date +%Y-%m-%d)"
```

### Patch Management

```bash
# Check for updates
sudo yum check-update

# Install security updates only
sudo yum update -y --security

# Full system update
sudo yum update -y

# List installed security updates
sudo yum updateinfo list security installed
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Cannot Connect via SSH

**Symptoms:**
- Connection timeout
- "Permission denied" errors
- "Host key verification failed"

**Solutions:**
```bash
# Check instance is running
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name'

# Verify security group allows your IP
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rhel8_security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'

# Check key permissions
chmod 400 my-rhel8-key.pem

# Verify correct username
ssh -i my-rhel8-key.pem ec2-user@$INSTANCE_IP  # ✅ Correct
ssh -i my-rhel8-key.pem root@$INSTANCE_IP      # ❌ Wrong
```

#### 2. Module Not Found

**Error:**
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider localterraform.com/ag/instance/aws
```

**Solutions:**
```bash
# Verify module registry configuration in ~/.terraformrc or terraform.tf
# Ensure network connectivity to internal registry
# Check authentication credentials for registry
```

#### 3. Insufficient Permissions

**Error:**
```
Error: Error launching source instance: UnauthorizedOperation
```

**Solutions:**
```bash
# Verify IAM permissions
aws sts get-caller-identity

# Required IAM actions:
# - ec2:RunInstances
# - ec2:CreateTags
# - ec2:DescribeInstances
# - ec2:DescribeImages
```

#### 4. Instance Limit Exceeded

**Error:**
```
Error: Error launching source instance: InstanceLimitExceeded
```

**Solutions:**
```bash
# Check current limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A

# Request limit increase via AWS Console or:
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 50
```

### Debug Mode

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

## Best Practices

### 1. Security Best Practices

✅ **Always encrypt root volumes in production**
```hcl
encrypt_root_volume = true
```

✅ **Restrict SSH access to known IP ranges**
```hcl
allowed_ssh_cidrs = ["YOUR_OFFICE_IP/24"]
```

✅ **Use IAM roles instead of access keys when possible**

✅ **Regularly update security patches**
```bash
sudo yum update -y --security
```

✅ **Enable CloudWatch detailed monitoring**

✅ **Implement AWS Systems Manager for secure access**

### 2. High Availability

✅ **Deploy across multiple availability zones**
```hcl
# Create module instances in different AZs
availability_zone = "us-east-1a"  # Instance 1
availability_zone = "us-east-1b"  # Instance 2
```

✅ **Use Elastic IPs for stable addressing**

✅ **Implement Auto Scaling Groups for production**

✅ **Configure health checks**

### 3. Cost Optimization

✅ **Right-size instance types based on actual usage**

✅ **Use gp3 volumes for better price/performance**

✅ **Enable detailed billing and cost allocation tags**

✅ **Consider Reserved Instances for long-term workloads**

✅ **Implement auto-shutdown for non-production environments**

### 4. Operational Excellence

✅ **Use consistent naming conventions**
```hcl
instance_name = "${var.project_name}-${var.environment}-rhel8-${var.purpose}"
```

✅ **Implement comprehensive tagging strategy**

✅ **Maintain documentation in version control**

✅ **Set up automated backups**

✅ **Regular security audits and compliance checks**

### 5. Disaster Recovery

✅ **Regular automated backups**

✅ **Test recovery procedures**

✅ **Document RTO (Recovery Time Objective) and RPO (Recovery Point Objective)**

✅ **Multi-region deployment for critical workloads**

✅ **Maintain configuration in version control**

## Additional Resources

### Official Documentation

- [Red Hat Enterprise Linux on AWS](https://aws.amazon.com/partners/redhat/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [RHEL 8 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8)

### Related Files

- `rhel8_deployment.tf` - Main Terraform configuration
- `main.tf` - Infrastructure foundation (VPC, networking)
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `terraform.tfvars.rhel8.example` - Example configuration

### Support

For issues or questions:
1. Check this documentation
2. Review Terraform logs with debug mode enabled
3. Consult AWS documentation
4. Contact Platform Engineering team

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: Platform Engineering Team
