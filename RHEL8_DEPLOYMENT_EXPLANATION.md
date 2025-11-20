# RedHat 8 VM Provisioning - Comprehensive Explanation

## Overview

This Terraform configuration (`rhel8_deployment.tf`) provides a complete, production-ready solution for provisioning RedHat Enterprise Linux 8 (RHEL 8) virtual machines on AWS using a custom Terraform module.

---

## Module Information

**Module Source**: `localterraform.com/ag/instance/aws`

This is a private/custom Terraform module hosted on a local Terraform registry. The module abstracts the complexity of AWS EC2 instance provisioning and provides a standardized interface for deploying instances across your organization.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                   │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │         Public Subnet (10.0.1.0/24)              │  │ │
│  │  │                                                    │  │ │
│  │  │  ┌──────────────────────────────────────────┐    │  │ │
│  │  │  │     Security Group (Firewall Rules)      │    │  │ │
│  │  │  │  - SSH (Port 22)                         │    │  │ │
│  │  │  │  - HTTP (Port 80)                        │    │  │ │
│  │  │  │  - HTTPS (Port 443)                      │    │  │ │
│  │  │  │                                           │    │  │ │
│  │  │  │  ┌────────────────────────────────────┐ │    │  │ │
│  │  │  │  │   RHEL 8 EC2 Instance              │ │    │  │ │
│  │  │  │  │   - t3.medium (2 vCPU, 4GB RAM)    │ │    │  │ │
│  │  │  │  │   - 50 GB gp3 Encrypted Volume     │ │    │  │ │
│  │  │  │  │   - Public IP: X.X.X.X             │ │    │  │ │
│  │  │  │  │   - Private IP: 10.0.1.X           │ │    │  │ │
│  │  │  │  └────────────────────────────────────┘ │    │  │ │
│  │  │  └──────────────────────────────────────────┘    │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                          │ │
│  │  Internet Gateway ← Routes to Internet                  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Components Explained

### 1. **AMI Data Source**

```hcl
data "aws_ami" "redhat8" {
  most_recent = true
  owners      = ["309956199498"]
  
  filter {
    name   = "name"
    values = ["RHEL-8.*-x86_64-*"]
  }
}
```

**Purpose**: Automatically discovers the latest official RHEL 8 AMI from Red Hat.

**Benefits**:
- ✅ Always deploys with the latest patches and security updates
- ✅ No need to hardcode AMI IDs (which vary by region)
- ✅ Reduces manual maintenance
- ✅ Works consistently across all AWS regions

**How it works**: Queries AWS for the most recent AMI published by Red Hat (Account ID: 309956199498) that matches the RHEL 8 naming pattern.

---

### 2. **Module Block - Core VM Provisioning**

```hcl
module "redhat8_vm" {
  source = "localterraform.com/ag/instance/aws"
  
  # All configuration parameters...
}
```

This is the heart of the provisioning code. The module encapsulates all the complexity of creating an EC2 instance with proper networking, storage, and security configurations.

---

### 3. **Instance Configuration Parameters**

#### **instance_type** = `"t3.medium"`
- **Explanation**: Determines the compute capacity (CPU, memory, network performance)
- **t3.medium specs**: 2 vCPUs, 4 GB RAM, up to 5 Gbps network
- **Use case**: Suitable for moderate workloads, web servers, small applications
- **Alternatives**: 
  - `t3.small` (2 vCPU, 2 GB) - lighter workloads
  - `m5.large` (2 vCPU, 8 GB) - memory-intensive applications
  - `c5.xlarge` (4 vCPU, 8 GB) - compute-intensive applications

#### **key_name** = `var.key_name`
- **Explanation**: SSH key pair for secure access to the VM
- **Requirement**: Must be created in AWS EC2 before running terraform
- **Usage**: `ssh -i <key_name>.pem ec2-user@<public_ip>`
- **Security**: Private key should never be committed to version control

#### **instance_name** = `"${var.project_name}-${var.environment}-rhel8-vm"`
- **Explanation**: Human-readable name displayed in AWS Console
- **Example**: `"myapp-production-rhel8-vm"`
- **Best practice**: Include environment (dev/staging/prod) and purpose

---

### 4. **Network Configuration Parameters**

#### **subnet_id** = `aws_subnet.public.id`
- **Explanation**: Specifies which VPC subnet to launch the instance in
- **Public subnet**: Instance gets a public IP, accessible from internet
- **Private subnet**: Instance only accessible within VPC
- **Reference**: Uses the subnet created in the main.tf file

#### **security_group_ids** = `[aws_security_group.redhat_sg.id]`
- **Explanation**: Firewall rules controlling network access
- **Format**: List of security group IDs (can attach multiple groups)
- **Current rules**: SSH (22), HTTP (80), HTTPS (443)
- **Best practice**: Use separate security groups for different functions

#### **availability_zone** = `data.aws_availability_zones.available.names[0]`
- **Explanation**: Physical data center location within AWS region
- **Example**: `"us-east-1a"`, `"us-west-2b"`
- **Importance**: Critical for high availability and disaster recovery
- **Note**: Must match the availability zone of the selected subnet

---

### 5. **Storage Configuration Parameters**

#### **root_volume_type** = `"gp3"`
- **Explanation**: Type of EBS (Elastic Block Store) volume for the root filesystem
- **gp3 advantages**:
  - Latest generation general purpose SSD
  - Better price-to-performance ratio than gp2
  - 3,000 IOPS baseline (vs 100-16,000 IOPS on gp2)
  - 125 MB/s throughput baseline
- **Cost**: Approximately $0.08 per GB-month (us-east-1)

#### **root_volume_size** = `50`
- **Explanation**: Size of root disk in gigabytes (GB)
- **RHEL 8 requirements**: Minimum 10 GB for base OS
- **50 GB sizing**: Provides space for:
  - Operating system (~10 GB)
  - Applications and dependencies (~20 GB)
  - Log files and temporary data (~10 GB)
  - User data and growth (~10 GB)
- **Scalability**: Can be increased later but not decreased

#### **encrypt_root_volume** = `true`
- **Explanation**: Enables EBS encryption at rest
- **Security benefits**:
  - Protects data if physical storage is compromised
  - Uses AWS-managed encryption keys (AES-256)
  - Transparent to applications (no code changes needed)
  - No performance impact on modern instance types
- **Compliance**: Required for PCI-DSS, HIPAA, SOC 2, and other frameworks
- **Cost**: No additional charge for EBS encryption

---

### 6. **Resource Tags**

```hcl
tags = {
  Environment  = var.environment
  OS           = "RHEL-8"
  Project      = var.project_name
  ManagedBy    = "Terraform"
  Owner        = "DevOps-Team"
  CostCenter   = "Engineering"
  Backup       = "Daily"
  Compliance   = "Standard"
  Purpose      = "Application-Server"
  DeployedDate = timestamp()
}
```

**Purpose of tags**:
1. **Cost Tracking**: Identify which resources belong to which projects/teams
2. **Automation**: Trigger backup jobs, monitoring, or maintenance based on tags
3. **Compliance**: Track which resources must meet specific compliance requirements
4. **Resource Management**: Easily find and organize resources in AWS Console
5. **Access Control**: Use tags in IAM policies for fine-grained permissions

**Tag best practices**:
- Always include Environment, Owner, and ManagedBy tags
- Use consistent tag naming across all resources
- Add CostCenter tag for financial tracking
- Include Purpose tag to document resource function

---

## Module Outputs

The configuration provides 7 outputs for easy access to important information:

| Output | Purpose | Example Value |
|--------|---------|---------------|
| `rhel8_instance_id` | Unique AWS identifier | `i-0123456789abcdef0` |
| `rhel8_public_ip` | Internet-accessible IP | `54.123.45.67` |
| `rhel8_private_ip` | VPC-internal IP | `10.0.1.25` |
| `rhel8_availability_zone` | Physical location | `us-east-1a` |
| `rhel8_ami_id` | AMI used | `ami-0abcdef1234567890` |
| `rhel8_ami_name` | AMI details | `RHEL-8.7-x86_64-...` |
| `rhel8_ssh_connection` | Ready-to-use SSH command | `ssh -i ~/.ssh/...` |

**Using outputs**:
```bash
# Get specific output
terraform output rhel8_public_ip

# Get all outputs in JSON format
terraform output -json

# Use output in scripts
PUBLIC_IP=$(terraform output -raw rhel8_public_ip)
ssh -i ~/.ssh/mykey.pem ec2-user@$PUBLIC_IP
```

---

## Deployment Workflow

### Step 1: Prerequisites

1. **AWS Credentials**: Configure AWS CLI or set environment variables
   ```bash
   aws configure
   # OR
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```

2. **Create SSH Key Pair** in AWS EC2 Console:
   - Navigate to EC2 → Key Pairs → Create Key Pair
   - Download the .pem file
   - Set permissions: `chmod 400 mykey.pem`

3. **Network Infrastructure**: Ensure VPC, subnet, and internet gateway exist
   - Provided by the main.tf in this repository

### Step 2: Initialize Terraform

```bash
cd /projects/sandbox/deployVM
terraform init
```

This downloads the required providers and modules.

### Step 3: Review the Plan

```bash
terraform plan
```

This shows what resources will be created, modified, or destroyed.

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### Step 5: Verify Deployment

```bash
# Get instance details
terraform output

# Test SSH connection
ssh -i ~/.ssh/mykey.pem ec2-user@$(terraform output -raw rhel8_public_ip)
```

---

## Post-Deployment Configuration

### Initial System Setup

```bash
# Connect to the instance
ssh -i ~/.ssh/mykey.pem ec2-user@<public_ip>

# Update all packages
sudo yum update -y

# Install common utilities
sudo yum install -y htop vim wget curl net-tools

# Check system information
cat /etc/redhat-release  # Verify RHEL version
df -h                    # Check disk space
free -h                  # Check memory
```

### Register with Red Hat Subscription Manager (RHSM)

```bash
# Register the system (requires Red Hat account)
sudo subscription-manager register --username=<your-username>

# Attach a subscription
sudo subscription-manager attach --auto

# Verify registration
sudo subscription-manager status
```

### Configure Firewall

```bash
# Check firewall status
sudo firewall-cmd --state

# Add services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Reload firewall
sudo firewall-cmd --reload

# List active rules
sudo firewall-cmd --list-all
```

---

## Security Best Practices

1. **SSH Access**: Restrict security group to specific IP ranges, not 0.0.0.0/0
2. **Regular Updates**: Run `sudo yum update` weekly or enable automatic updates
3. **Monitoring**: Enable CloudWatch monitoring for CPU, disk, and network metrics
4. **Backups**: Configure automated EBS snapshots or use AWS Backup
5. **IAM Roles**: Attach IAM roles to instances instead of using access keys
6. **Secrets Management**: Use AWS Secrets Manager or Parameter Store for sensitive data
7. **Logging**: Configure CloudWatch Logs agent for centralized log management
8. **Hardening**: Follow CIS RedHat Enterprise Linux 8 Benchmark

---

## Cost Estimation

**Monthly costs for this configuration (us-east-1 region)**:

| Component | Specification | Monthly Cost |
|-----------|--------------|--------------|
| EC2 Instance | t3.medium (730 hrs/month) | ~$30.37 |
| EBS Storage | 50 GB gp3 | ~$4.00 |
| Data Transfer | 1 TB outbound | ~$90.00 |
| **Subtotal** | | **~$124.37** |

**Cost optimization tips**:
- Use Reserved Instances for long-running workloads (up to 72% savings)
- Stop instances during non-business hours (dev/test environments)
- Use Savings Plans for flexible commitment-based discounts
- Monitor and delete unused EBS snapshots
- Use VPC endpoints to reduce data transfer costs

---

## Troubleshooting

### Issue: Cannot connect via SSH

**Solutions**:
1. Check security group allows SSH (port 22) from your IP
2. Verify key pair matches: `ssh-keygen -lf mykey.pem`
3. Ensure instance is in running state: `terraform output rhel8_instance_id`
4. Check network ACLs allow traffic
5. Verify public IP is assigned: `terraform output rhel8_public_ip`

### Issue: "No space left on device"

**Solutions**:
1. Check disk usage: `df -h`
2. Clean package cache: `sudo yum clean all`
3. Remove old kernels: `sudo package-cleanup --oldkernels --count=2`
4. Increase root volume size in Terraform and run `terraform apply`

### Issue: Performance is slow

**Solutions**:
1. Check instance metrics in CloudWatch
2. Upgrade to larger instance type in Terraform configuration
3. Monitor CPU/memory: `htop` or `top`
4. Check disk I/O: `iostat -x 1`
5. Consider using larger instance type or provisioned IOPS volumes

---

## Terraform Module Parameters Reference

All parameters used in the module configuration:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `instance_type` | string | Yes | EC2 instance type (CPU/RAM configuration) |
| `key_name` | string | Yes | SSH key pair name for access |
| `instance_name` | string | Yes | Name tag for the instance |
| `subnet_id` | string | Yes | VPC subnet ID for instance placement |
| `security_group_ids` | list(string) | Yes | List of security group IDs |
| `availability_zone` | string | Yes | AWS availability zone |
| `root_volume_type` | string | Yes | EBS volume type (gp2, gp3, io1, io2) |
| `root_volume_size` | number | Yes | Root volume size in GB |
| `encrypt_root_volume` | bool | Yes | Enable EBS encryption |
| `tags` | map(string) | Yes | Additional resource tags |

---

## Additional Resources

- **RHEL 8 Documentation**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8
- **AWS EC2 Documentation**: https://docs.aws.amazon.com/ec2/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/

---

## Summary

This Terraform configuration provides a complete, secure, and production-ready solution for deploying RedHat 8 VMs on AWS. It includes:

✅ Automatic selection of latest RHEL 8 AMI  
✅ Secure encrypted storage  
✅ Proper network configuration  
✅ Comprehensive tagging for management  
✅ Detailed outputs for easy access  
✅ Production-grade instance specifications  
✅ High availability zone placement  

The code is ready to use and can be customized by modifying the variable values to fit specific requirements.
