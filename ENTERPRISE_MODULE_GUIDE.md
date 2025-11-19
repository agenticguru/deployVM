# RedHat 7 EC2 Instance - Enterprise Module Deployment Guide

## Overview

This guide provides complete instructions for deploying a production-ready RedHat Enterprise Linux 7 EC2 instance using the Terraform enterprise module from `localterraform.com/ag/instance/aws` version `~> 3.0`.

**Module Information:**
- **Source:** `localterraform.com/ag/instance/aws`
- **Version:** `~> 3.0`
- **Operating System:** RedHat Enterprise Linux 7 (RHEL 7)
- **Architecture:** x86_64 (64-bit)
- **AMI Owner:** Red Hat, Inc. (Account: 309956199498)

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Configuration Details](#configuration-details)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment](#post-deployment)
7. [Cost Estimation](#cost-estimation)
8. [Security Best Practices](#security-best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance and Updates](#maintenance-and-updates)

---

## Prerequisites

### Required Tools

1. **Terraform** (version >= 1.0)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform --version
   ```

2. **AWS CLI** (version 2.x)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws --version
   ```

3. **Git** (for version control)
   ```bash
   sudo yum install -y git
   ```

### AWS Requirements

1. **AWS Account** with appropriate permissions
2. **IAM User/Role** with the following permissions:
   - ec2:RunInstances
   - ec2:CreateTags
   - ec2:DescribeInstances
   - ec2:DescribeImages
   - ec2:DescribeSecurityGroups
   - ec2:DescribeSubnets
   - ec2:DescribeVpcs
   - ec2:DescribeAvailabilityZones
   - ec2:CreateVpc
   - ec2:CreateSubnet
   - ec2:CreateInternetGateway
   - ec2:CreateRouteTable
   - ec2:CreateSecurityGroup

3. **EC2 Key Pair** created in target region
4. **AWS Credentials** configured

### Configure AWS Credentials

```bash
# Option 1: Using AWS CLI
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region, Output format

# Option 2: Using Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: Using IAM Role (if running on EC2)
# No configuration needed - automatic
```

### Create EC2 Key Pair

```bash
# Create a new key pair
aws ec2 create-key-pair \
  --key-name my-redhat-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > my-redhat-key.pem

# Set proper permissions
chmod 400 my-redhat-key.pem

# Verify key pair was created
aws ec2 describe-key-pairs --key-names my-redhat-key --region us-east-1
```

---

## Architecture Overview

### Infrastructure Components

The deployment creates the following AWS resources:

```
┌─────────────────────────────────────────────────────────────┐
│                          AWS Region                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   VPC (10.0.0.0/16)                   │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │          Public Subnet (10.0.1.0/24)            │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │     RedHat 7 EC2 Instance                 │  │  │  │
│  │  │  │  ┌─────────────────────────────────────┐  │  │  │  │
│  │  │  │  │ • Instance Type: t3.micro           │  │  │  │  │
│  │  │  │  │ • OS: RHEL 7 x86_64                 │  │  │  │  │
│  │  │  │  │ • Storage: 20 GB gp3 (encrypted)    │  │  │  │  │
│  │  │  │  │ • Public IP: Auto-assigned          │  │  │  │  │
│  │  │  │  │ • Security Group: SSH/HTTP/HTTPS    │  │  │  │  │
│  │  │  │  └─────────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  │                                                   │  │  │
│  │  │  [Route Table] ──► [Internet Gateway]            │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  [Security Group Rules]                                │  │
│  │  • Inbound: SSH (22), HTTP (80), HTTPS (443)          │  │
│  │  • Outbound: All traffic                              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Resource Naming Convention

All resources follow the pattern: `{project_name}-{environment}-{resource_type}`

Example:
- VPC: `redhat-deployment-dev-vpc`
- Subnet: `redhat-deployment-dev-public-subnet`
- Instance: `redhat-deployment-dev-redhat7`
- Security Group: `redhat-deployment-dev-redhat7-sg`

---

## Quick Start

### 1. Clone or Navigate to Repository

```bash
cd /path/to/deployVM
```

### 2. Create Configuration File

```bash
# Copy the example configuration
cp terraform.tfvars.enterprise_module.example terraform.tfvars

# Edit with your specific values
vi terraform.tfvars
```

### 3. Minimal Configuration

Edit `terraform.tfvars` with at minimum:

```hcl
aws_region = "us-east-1"
key_name   = "my-redhat-key"  # Your EC2 key pair name
```

### 4. Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### 5. Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### 6. Plan Deployment

```bash
terraform plan
```

Review the plan output to see what resources will be created.

### 7. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 8. Access Your Instance

```bash
# Get the public IP
terraform output instance_public_ip

# SSH to the instance
ssh -i my-redhat-key.pem ec2-user@<public_ip>
```

---

## Configuration Details

### Core Parameters (REQUIRED)

| Parameter | Description | Example | Required |
|-----------|-------------|---------|----------|
| `key_name` | EC2 key pair name for SSH access | "my-redhat-key" | **YES** |
| `instance_type` | EC2 instance type | "t3.micro" | No (has default) |

### Networking Parameters

| Parameter | Description | Default | Recommended |
|-----------|-------------|---------|-------------|
| `vpc_cidr` | VPC CIDR block | "10.0.0.0/16" | Use non-overlapping CIDR |
| `public_subnet_cidr` | Public subnet CIDR | "10.0.1.0/24" | Must be within VPC CIDR |
| `subnet_id` | Subnet ID for instance | Auto-created | Required by module |
| `security_group_ids` | Security group IDs | Auto-created | Required by module |
| `availability_zone` | AWS availability zone | Auto-selected | First available AZ |
| `associate_public_ip_address` | Assign public IP | true | true for public access |

### Storage Parameters

| Parameter | Description | Default | Production |
|-----------|-------------|---------|------------|
| `root_volume_type` | EBS volume type | "gp3" | "gp3" (recommended) |
| `root_volume_size` | Volume size in GB | 20 | 50-100 GB |
| `encrypt_root_volume` | Enable encryption | true | **Always true** |
| `delete_on_termination` | Delete volume on termination | true | false (for prod) |

### Security Parameters

| Parameter | Description | Default | Production |
|-----------|-------------|---------|------------|
| `allowed_ssh_cidrs` | CIDR blocks for SSH access | ["0.0.0.0/0"] | **Restrict to VPN/office** |
| `enable_http_access` | Allow HTTP (port 80) | false | Based on need |
| `enable_https_access` | Allow HTTPS (port 443) | false | Based on need |

### Tags and Metadata

| Parameter | Description | Default |
|-----------|-------------|---------|
| `project_name` | Project identifier | "redhat-deployment" |
| `environment` | Environment name | "dev" |
| `owner` | Resource owner | "DevOps-Team" |
| `cost_center` | Cost allocation | "Engineering" |
| `backup_policy` | Backup frequency | "daily" |
| `compliance_requirements` | Compliance needs | "General" |

### Monitoring Parameters

| Parameter | Description | Default | Production |
|-----------|-------------|---------|------------|
| `enable_detailed_monitoring` | 1-minute CloudWatch metrics | false | true |
| `enable_cloudwatch_alarms` | Enable alarms | false | true |
| `cpu_alarm_threshold` | CPU alert threshold (%) | 80 | 70-80 |

---

## Deployment Steps

### Step-by-Step Deployment Process

#### Step 1: Pre-Deployment Validation

Run the validation script (if available):

```bash
./validate_setup.sh
```

Or manually verify:

```bash
# Check Terraform version
terraform version

# Check AWS credentials
aws sts get-caller-identity

# Check key pair exists
aws ec2 describe-key-pairs --key-names my-redhat-key

# Check available AMIs
aws ec2 describe-images \
  --owners 309956199498 \
  --filters "Name=name,Values=RHEL-7.*-x86_64-*" \
  --query 'Images[0].[ImageId,Name,CreationDate]' \
  --output table
```

#### Step 2: Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init

# Expected output shows successful initialization
```

#### Step 3: Format and Validate

```bash
# Format Terraform files
terraform fmt

# Validate configuration
terraform validate
```

#### Step 4: Plan the Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan output carefully
# Verify:
# - Resource names are correct
# - Network configuration is appropriate
# - Security groups have proper rules
# - Tags are properly set
```

#### Step 5: Apply the Configuration

```bash
# Apply the planned changes
terraform apply tfplan

# Or apply with auto-approval (use with caution)
terraform apply -auto-approve
```

Deployment typically takes 2-5 minutes.

#### Step 6: Capture Outputs

```bash
# View all outputs
terraform output

# Get specific outputs
terraform output instance_id
terraform output instance_public_ip
terraform output ssh_connection_command

# Save deployment summary
terraform output -json deployment_summary > deployment_info.json
```

#### Step 7: Verify Deployment

```bash
# Check instance status
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,PrivateIpAddress]' \
  --output table

# Wait for instance to be fully running
aws ec2 wait instance-running \
  --instance-ids $(terraform output -raw instance_id)

# Check instance status checks
aws ec2 describe-instance-status \
  --instance-ids $(terraform output -raw instance_id)
```

---

## Post-Deployment

### Initial Access and Verification

#### 1. SSH Access

```bash
# Get connection command from output
terraform output ssh_connection_command

# Or manually connect
ssh -i my-redhat-key.pem ec2-user@$(terraform output -raw instance_public_ip)
```

#### 2. Verify System Information

Once logged in via SSH:

```bash
# Check RHEL version
cat /etc/redhat-release
# Expected: Red Hat Enterprise Linux Server release 7.x

# Check system resources
free -h
df -h
top

# Check network configuration
ip addr
ip route
netstat -tulpn

# Verify user data script execution
sudo cat /var/log/user-data.log
sudo cat /var/log/deployment.log

# Check installed packages
rpm -qa | grep -E 'htop|wget|curl|vim'

# View MOTD
cat /etc/motd
```

#### 3. System Updates

```bash
# Update system packages
sudo yum update -y

# Install additional packages if needed
sudo yum install -y package-name

# Reboot if kernel was updated
sudo reboot
```

#### 4. Configure Application

Install and configure your application:

```bash
# Example: Install Apache web server
sudo yum install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd

# Create a test page
echo "<h1>Hello from RHEL 7</h1>" | sudo tee /var/www/html/index.html

# Test locally
curl http://localhost

# Access from browser: http://<public_ip>
```

### Security Hardening

#### 1. Update Security Group Rules

```bash
# Get your current IP
MY_IP=$(curl -s https://api.ipify.org)

# Update security group to restrict SSH
aws ec2 authorize-security-group-ingress \
  --group-id $(terraform output -raw security_group_id) \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32

# Revoke the open SSH rule
aws ec2 revoke-security-group-ingress \
  --group-id $(terraform output -raw security_group_id) \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

#### 2. Configure Firewall

```bash
# Enable firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Allow services
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Reload firewall
sudo firewall-cmd --reload

# Check status
sudo firewall-cmd --list-all
```

#### 3. Configure SELinux

```bash
# Check SELinux status
getenforce
sestatus

# SELinux should be in Enforcing mode for security
# If in Permissive mode, enable it:
sudo setenforce 1

# Make it persistent
sudo vi /etc/selinux/config
# Set: SELINUX=enforcing
```

#### 4. Enable Automatic Updates

```bash
# Install yum-cron
sudo yum install -y yum-cron

# Configure for automatic security updates
sudo vi /etc/yum/yum-cron.conf
# Set: apply_updates = yes

# Enable and start service
sudo systemctl enable yum-cron
sudo systemctl start yum-cron
```

### Monitoring Setup

#### 1. Install CloudWatch Agent

```bash
# Download CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm

# Install
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

#### 2. Set Up Log Monitoring

```bash
# Configure log shipping to CloudWatch
sudo vi /opt/aws/amazon-cloudwatch-agent/etc/config.json

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent
```

### Backup Configuration

#### 1. Enable AWS Backup

```bash
# Create backup plan (via AWS Console or CLI)
aws backup create-backup-plan \
  --backup-plan file://backup-plan.json

# Associate resources with backup plan
aws backup create-backup-selection \
  --backup-plan-id <plan-id> \
  --backup-selection file://backup-selection.json
```

#### 2. Create AMI Snapshot

```bash
# Create AMI for disaster recovery
aws ec2 create-image \
  --instance-id $(terraform output -raw instance_id) \
  --name "RHEL7-backup-$(date +%Y%m%d)" \
  --description "Backup of RHEL 7 instance" \
  --no-reboot
```

---

## Cost Estimation

### Monthly Cost Breakdown (US East Region)

#### Development Environment

```
Instance (t3.micro):        $7.59/month
Storage (20 GB gp3):        $2.00/month
Data Transfer (1 GB):       $0.09/month
RHEL License:               Included in instance cost
─────────────────────────────────────────
TOTAL:                      ~$10/month
```

#### Staging Environment

```
Instance (t3.medium):       $30.37/month
Storage (50 GB gp3):        $5.00/month
Data Transfer (5 GB):       $0.45/month
Detailed Monitoring:        $2.10/month
CloudWatch Alarms (2):      $0.20/month
─────────────────────────────────────────
TOTAL:                      ~$38/month
```

#### Production Environment

```
Instance (m5.large):        $70.08/month
Storage (100 GB gp3):       $10.00/month
Elastic IP:                 $0.00/month (if attached)
Data Transfer (20 GB):      $1.80/month
Detailed Monitoring:        $2.10/month
CloudWatch Alarms (5):      $0.50/month
AWS Backup:                 $5.00/month
─────────────────────────────────────────
TOTAL:                      ~$90/month
```

### Cost Optimization Tips

1. **Right-size instances**: Start small and scale up
2. **Use gp3 volumes**: Better price/performance than gp2
3. **Stop dev/test instances** when not in use
4. **Reserved Instances**: Save up to 72% for long-term workloads
5. **Savings Plans**: Flexible cost savings option
6. **Monitor usage**: Use AWS Cost Explorer

---

## Security Best Practices

### 1. Network Security

- ✅ **Restrict SSH access** to known IP ranges
- ✅ **Use VPN or bastion host** for production access
- ✅ **Enable VPC Flow Logs** for network monitoring
- ✅ **Implement Network ACLs** for additional security layer
- ✅ **Use private subnets** for production workloads

### 2. Access Control

- ✅ **Use IAM roles** instead of access keys
- ✅ **Enable MFA** for AWS console access
- ✅ **Implement least privilege** permissions
- ✅ **Rotate SSH keys** regularly
- ✅ **Use AWS Systems Manager Session Manager** as SSH alternative

### 3. Data Protection

- ✅ **Always encrypt** EBS volumes
- ✅ **Use KMS custom keys** for sensitive data
- ✅ **Enable encryption** in transit (TLS/SSL)
- ✅ **Regular backups** with automated retention
- ✅ **Test restore procedures** regularly

### 4. Monitoring and Logging

- ✅ **Enable CloudTrail** for API audit logs
- ✅ **Configure CloudWatch alarms** for critical metrics
- ✅ **Ship logs** to centralized logging solution
- ✅ **Monitor failed login attempts**
- ✅ **Set up billing alerts**

### 5. System Security

- ✅ **Keep system updated**: `sudo yum update -y`
- ✅ **Enable SELinux** in enforcing mode
- ✅ **Configure firewalld** properly
- ✅ **Disable unnecessary services**
- ✅ **Regular security audits**

### 6. Compliance

- ✅ **Document architecture** and configurations
- ✅ **Maintain change logs**
- ✅ **Implement tagging strategy** for governance
- ✅ **Regular compliance reviews**
- ✅ **Automated compliance checks** (AWS Config)

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Terraform Init Fails

**Symptoms:**
```
Error: Failed to download provider
```

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init

# If behind proxy, set environment variables
export HTTP_PROXY="http://proxy:port"
export HTTPS_PROXY="http://proxy:port"
terraform init
```

#### Issue 2: Authentication Error

**Symptoms:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# If not configured, run:
aws configure

# Or set environment variables:
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

#### Issue 3: Key Pair Not Found

**Symptoms:**
```
Error: InvalidKeyPair.NotFound: The key pair 'my-key' does not exist
```

**Solution:**
```bash
# List existing key pairs
aws ec2 describe-key-pairs --region us-east-1

# Create new key pair
aws ec2 create-key-pair \
  --key-name my-redhat-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > my-redhat-key.pem

chmod 400 my-redhat-key.pem

# Update terraform.tfvars with correct key name
```

#### Issue 4: Cannot SSH to Instance

**Symptoms:**
```
ssh: connect to host x.x.x.x port 22: Connection refused/timeout
```

**Solution:**
```bash
# Check instance is running
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id)

# Verify your IP is allowed
curl https://api.ipify.org

# Check system logs
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id)

# Verify network connectivity
ping $(terraform output -raw instance_public_ip)
telnet $(terraform output -raw instance_public_ip) 22
```

#### Issue 5: Module Not Found

**Symptoms:**
```
Error: Module not found
```

**Solution:**

If using local registry:
```bash
# Verify module registry is accessible
curl https://localterraform.com/ag/instance/aws

# Check network/VPN connection
# Contact your Terraform Enterprise administrator
```

#### Issue 6: Insufficient Capacity

**Symptoms:**
```
Error: InsufficientInstanceCapacity or VcpuLimitExceeded
```

**Solution:**
```bash
# Try different instance type
# Edit terraform.tfvars:
instance_type = "t3.small"  # instead of t3.micro

# Or try different availability zone
# The configuration will auto-select first available AZ

# Request limit increase if needed
# AWS Console → Service Quotas → EC2
```

#### Issue 7: Terraform State Lock

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# If using remote backend with DynamoDB
# Check if lock is stale
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution)
terraform force-unlock <lock-id>

# If using local state, check for .terraform.tfstate.lock.info file
rm -f .terraform.tfstate.lock.info
```

### Debug Mode

Enable Terraform debug logging:

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run Terraform command
terraform apply

# Review debug log
cat terraform-debug.log
```

### Get Instance Console Output

```bash
# View instance console output (useful for boot issues)
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id) \
  --output text
```

### Check CloudWatch Logs

```bash
# View CloudWatch logs (if agent is installed)
aws logs tail /aws/ec2/$(terraform output -raw instance_id) --follow
```

---

## Maintenance and Updates

### Regular Maintenance Tasks

#### Daily

- Monitor CloudWatch alarms
- Review CloudWatch logs for errors
- Check disk space: `df -h`

#### Weekly

- Review security logs: `sudo grep -i error /var/log/messages`
- Check failed login attempts: `sudo lastb`
- Review CloudTrail logs
- Verify backups are running

#### Monthly

- Apply system updates: `sudo yum update -y`
- Review and optimize costs
- Rotate SSH keys
- Review and update security groups
- Test disaster recovery procedures
- Review compliance requirements

#### Quarterly

- Security audit
- Performance review and optimization
- Review and update documentation
- Capacity planning review

### Update System Packages

```bash
# Connect to instance
ssh -i my-redhat-key.pem ec2-user@$(terraform output -raw instance_public_ip)

# Check for available updates
sudo yum check-update

# Update all packages
sudo yum update -y

# If kernel was updated, reboot
sudo reboot
```

### Update Terraform Configuration

```bash
# Update configuration files
vi rhel7_enterprise_module.tf

# Format code
terraform fmt

# Validate changes
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Scale Instance

To change instance type:

```bash
# Edit terraform.tfvars
instance_type = "t3.medium"  # Change from t3.micro

# Plan the change
terraform plan

# Apply (instance will be stopped and restarted)
terraform apply
```

### Destroy Resources

When no longer needed:

```bash
# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with: yes
```

---

## Additional Resources

### Official Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Red Hat Enterprise Linux 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/)

### Repository Files

- `rhel7_enterprise_module.tf` - Main configuration
- `variables_enterprise_module.tf` - Variable definitions
- `outputs_enterprise.tf` - Output definitions
- `terraform.tfvars.enterprise_module.example` - Example configuration

### Support and Contact

For issues or questions:
1. Review this documentation
2. Check Terraform logs: `TF_LOG=DEBUG terraform apply`
3. Review AWS CloudWatch logs
4. Contact your DevOps team
5. Refer to RedHatProducts repository documentation

---

## Conclusion

This guide provides comprehensive instructions for deploying RedHat 7 EC2 instances using the enterprise Terraform module. Follow the security best practices and maintenance procedures to ensure a secure, reliable, and cost-effective deployment.

**Key Takeaways:**
- Always encrypt storage volumes
- Restrict security group access
- Enable monitoring and logging
- Regular updates and maintenance
- Follow least privilege principle
- Document all changes

---

**Document Version:** 1.0  
**Last Updated:** November 19, 2024  
**Module Version:** ~> 3.0  
**Author:** DevOps Team
