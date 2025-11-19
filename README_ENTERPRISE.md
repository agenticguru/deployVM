# RedHat 7 EC2 Instance - Enterprise Module Deployment

![RHEL 7](https://img.shields.io/badge/RHEL-7-red)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-purple)
![AWS](https://img.shields.io/badge/AWS-EC2-orange)
![Module](https://img.shields.io/badge/Module-v3.0-blue)

Production-ready Terraform configuration for deploying RedHat Enterprise Linux 7 EC2 instances using the enterprise module from `localterraform.com/ag/instance/aws`.

---

## 🎯 Overview

This repository contains a complete, production-ready Terraform configuration for provisioning RedHat Enterprise Linux 7 (RHEL 7) EC2 instances on AWS using the enterprise module structure.

### Key Features

✅ **Production-Ready**: Comprehensive security, monitoring, and compliance configurations  
✅ **Enterprise Module**: Uses `localterraform.com/ag/instance/aws` version `~> 3.0`  
✅ **Complete Infrastructure**: VPC, subnet, security groups, and networking  
✅ **Security-First**: Encryption, restricted access, and security best practices  
✅ **Well-Documented**: Extensive documentation and examples  
✅ **Flexible**: Easily configurable for dev, staging, and production environments  
✅ **Cost-Optimized**: Right-sized defaults with scalability options  

---

## 📁 Repository Structure

```
deployVM/
├── rhel7_enterprise_module.tf              # Main Terraform configuration
├── variables_enterprise_module.tf          # Variable definitions
├── outputs_enterprise.tf                   # Output definitions
├── terraform.tfvars.enterprise_module.example  # Example configuration
├── ENTERPRISE_MODULE_GUIDE.md              # Complete deployment guide
├── ENTERPRISE_QUICK_START.md               # Quick start guide
├── README_ENTERPRISE.md                    # This file
└── validate_setup.sh                       # Pre-deployment validation script
```

---

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- EC2 key pair in target region

### Deploy in 3 Steps

```bash
# 1. Create configuration
cp terraform.tfvars.enterprise_module.example terraform.tfvars
vi terraform.tfvars  # Edit: set key_name

# 2. Initialize and deploy
terraform init
terraform apply

# 3. Access instance
ssh -i your-key.pem ec2-user@$(terraform output -raw public_ip)
```

**⏱️ Deployment time: ~3-5 minutes**

---

## 📋 Module Structure

### Core Module Configuration

```hcl
module "vm_example_rh7" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 3.0"
  
  # Core Parameters
  instance_type = "t3.micro"
  key_name      = "my-key"
  instance_name = "redhat7-instance"
  
  # Networking (from RedHatProducts documentation)
  subnet_id              = aws_subnet.public.id
  security_group_ids     = [aws_security_group.sg.id]
  availability_zone      = "us-east-1a"
  
  # Storage (from RedHatProducts documentation)
  root_volume_type    = "gp3"
  root_volume_size    = 20
  encrypt_root_volume = true
  
  # RedHat-Specific (from RedHatProducts documentation)
  ami_owner_id     = "309956199498"
  ami_name_pattern = "RHEL-7.*-x86_64-*"
  
  # Tags and Metadata (from RedHatProducts documentation)
  tags = {
    Environment = "dev"
    Project     = "redhat-deployment"
    OS          = "RHEL-7"
    ManagedBy   = "Terraform"
  }
}
```

---

## 📖 Documentation

### Complete Guides

1. **[ENTERPRISE_MODULE_GUIDE.md](ENTERPRISE_MODULE_GUIDE.md)** - Complete deployment guide
   - Prerequisites and setup
   - Architecture overview
   - Step-by-step deployment
   - Post-deployment configuration
   - Security hardening
   - Troubleshooting

2. **[ENTERPRISE_QUICK_START.md](ENTERPRISE_QUICK_START.md)** - Quick reference
   - 5-minute deployment
   - Common configurations
   - Essential commands
   - Quick troubleshooting

3. **[RHEL7_PROVISIONING_PARAMETERS.md](../RHEL7_PROVISIONING_PARAMETERS.md)** - Parameter reference
   - All parameters from RedHatProducts
   - Detailed descriptions
   - Validation rules
   - Best practices

---

## 🔧 Configuration

### Required Parameters

Only **one** parameter is absolutely required:

```hcl
key_name = "my-redhat-key"  # EC2 key pair for SSH access
```

### Common Configuration Scenarios

#### Development Environment

```hcl
aws_region    = "us-east-1"
environment   = "dev"
instance_type = "t3.micro"
root_volume_size = 20
allowed_ssh_cidrs = ["0.0.0.0/0"]
enable_detailed_monitoring = false
```

**💰 Cost: ~$10/month**

#### Staging Environment

```hcl
aws_region    = "us-east-1"
environment   = "staging"
instance_type = "t3.medium"
root_volume_size = 50
allowed_ssh_cidrs = ["10.0.0.0/8"]
enable_detailed_monitoring = true
enable_cloudwatch_alarms = true
```

**💰 Cost: ~$38/month**

#### Production Environment

```hcl
aws_region    = "us-east-1"
environment   = "prod"
instance_type = "m5.large"
root_volume_size = 100
root_volume_type = "gp3"
encrypt_root_volume = true
create_elastic_ip = true
allowed_ssh_cidrs = ["10.0.0.0/8"]
enable_detailed_monitoring = true
enable_cloudwatch_alarms = true
backup_policy = "daily"
security_level = "Confidential"
```

**💰 Cost: ~$90/month**

---

## 📦 Parameters from RedHatProducts Repository

All parameters in this configuration are derived from the **RedHatProducts** repository documentation:

### Instance Parameters
- `instance_type` - From README.md instance type recommendations
- `key_name` - Required parameter from module documentation

### Networking Parameters
- `subnet_id` - Required for production deployments
- `security_group_ids` - Required for production deployments
- `availability_zone` - Required for production deployments
- `associate_public_ip_address` - Optional, defaults to true

### Storage Parameters
- `root_volume_type` - From volume type selection guide (gp2, gp3, io1, io2)
- `root_volume_size` - From volume size recommendations
- `encrypt_root_volume` - Security best practice (always true for production)
- `delete_on_termination` - Lifecycle management

### RedHat-Specific Parameters
- `ami_owner_id` - Red Hat official account (309956199498)
- `ami_name_pattern` - RHEL 7 filter pattern (RHEL-7.*-x86_64-*)

### Tags and Metadata
- `instance_name` - Instance identification
- `environment` - Environment classification (dev/staging/prod)
- `project_name` - Project identification
- `owner` - Resource ownership
- `cost_center` - Cost allocation
- Additional custom tags

### Monitoring Parameters
- `enable_detailed_monitoring` - CloudWatch detailed monitoring
- `enable_cloudwatch_alarms` - Alarm configuration
- `cpu_alarm_threshold` - CPU alert threshold

---

## 🏗️ Architecture

### Infrastructure Components

```
AWS Region (us-east-1)
│
├── VPC (10.0.0.0/16)
│   ├── Internet Gateway
│   ├── Public Subnet (10.0.1.0/24)
│   │   └── RedHat 7 EC2 Instance
│   │       ├── Instance Type: t3.micro (configurable)
│   │       ├── OS: RHEL 7 x86_64
│   │       ├── Storage: 20GB gp3 (encrypted)
│   │       ├── Public IP: Auto-assigned
│   │       └── Security Group: SSH/HTTP/HTTPS
│   ├── Route Table
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Security Group
│       ├── Inbound: SSH (22), HTTP (80), HTTPS (443)
│       └── Outbound: All traffic
│
├── CloudWatch (Optional)
│   ├── Detailed Monitoring
│   ├── CPU Utilization Alarm
│   └── Status Check Alarm
│
└── Elastic IP (Optional)
    └── Static IP Address
```

### Network Flow

```
Internet
   ↓
Internet Gateway
   ↓
Public Subnet (10.0.1.0/24)
   ↓
Security Group (Firewall)
   ↓
RedHat 7 EC2 Instance
   ├── SSH (Port 22)
   ├── HTTP (Port 80) - Optional
   └── HTTPS (Port 443) - Optional
```

---

## 🔐 Security Features

### Built-in Security

✅ **Encryption at Rest**: EBS volumes encrypted with AES-256  
✅ **Network Isolation**: Dedicated VPC with controlled access  
✅ **Security Groups**: Fine-grained network access control  
✅ **IAM Integration**: Role-based access control support  
✅ **Audit Logging**: CloudTrail integration ready  
✅ **Compliance Tags**: Support for compliance tracking  

### Security Best Practices Implemented

1. **Default Encryption**: Root volumes encrypted by default
2. **Restricted Access**: Configurable SSH CIDR restrictions
3. **Secure AMIs**: Only official Red Hat AMIs (verified owner)
4. **Network Security**: Dedicated security groups with minimal rules
5. **Monitoring**: CloudWatch integration for security monitoring
6. **Tagging**: Comprehensive tagging for governance

### Post-Deployment Hardening

```bash
# Restrict SSH to your IP
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Enable firewall
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Keep system updated
sudo yum update -y

# Enable SELinux
sudo setenforce 1
```

---

## 📊 Outputs

### Available Outputs

The configuration provides comprehensive outputs for easy access and integration:

```bash
# Network Information
terraform output vpc_id
terraform output public_ip
terraform output private_ip
terraform output security_group_id

# Instance Information
terraform output instance_id
terraform output instance_type
terraform output availability_zone

# Access Information
terraform output ssh_connection_command
terraform output ssh_user

# AMI Information
terraform output ami_id
terraform output ami_name

# Complete Summary
terraform output deployment_summary
```

### Example Output

```bash
$ terraform output deployment_summary

{
  "instance_id" = "i-0123456789abcdef0"
  "instance_type" = "t3.micro"
  "public_ip" = "54.123.45.67"
  "private_ip" = "10.0.1.100"
  "ami_id" = "ami-0123456789abcdef0"
  "ami_name" = "RHEL-7.9-x86_64-2024-01-01"
  "ssh_command" = "ssh -i my-key.pem ec2-user@54.123.45.67"
  ...
}
```

---

## 💰 Cost Estimation

### Monthly Cost Breakdown

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| **Instance** | t3.micro<br>$7.59 | t3.medium<br>$30.37 | m5.large<br>$70.08 |
| **Storage** | 20 GB gp3<br>$2.00 | 50 GB gp3<br>$5.00 | 100 GB gp3<br>$10.00 |
| **Monitoring** | Basic<br>$0.00 | Detailed<br>$2.10 | Detailed<br>$2.10 |
| **Alarms** | None<br>$0.00 | 2 alarms<br>$0.20 | 5 alarms<br>$0.50 |
| **Backup** | None<br>$0.00 | None<br>$0.00 | Daily<br>$5.00 |
| **Data Transfer** | 1 GB<br>$0.09 | 5 GB<br>$0.45 | 20 GB<br>$1.80 |
| **TOTAL** | **~$10/month** | **~$38/month** | **~$90/month** |

*Prices are estimates for US East (N. Virginia) region as of 2024.*

### Cost Optimization Tips

1. **Right-size instances**: Start with smaller types
2. **Use gp3 volumes**: Better price/performance than gp2
3. **Stop unused instances**: Stop dev/test when not needed
4. **Reserved Instances**: Save up to 72% for 1-3 year commitments
5. **Savings Plans**: Flexible pricing for compute usage
6. **Monitor with AWS Cost Explorer**: Track and optimize spending

---

## 🧪 Testing and Validation

### Pre-Deployment Validation

```bash
# Run validation script
./validate_setup.sh

# Manual validation
terraform fmt -check
terraform validate
terraform plan
```

### Post-Deployment Testing

```bash
# Check instance is running
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# Test SSH connectivity
ssh -i your-key.pem ec2-user@$(terraform output -raw public_ip) 'echo "Connected successfully"'

# Verify RHEL version
ssh -i your-key.pem ec2-user@$(terraform output -raw public_ip) 'cat /etc/redhat-release'

# Check disk encryption
ssh -i your-key.pem ec2-user@$(terraform output -raw public_ip) 'lsblk -f'
```

---

## 🔄 Lifecycle Management

### Update Instance

```bash
# Update configuration
vi terraform.tfvars

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Scale Instance

```bash
# Change instance type
echo 'instance_type = "t3.medium"' >> terraform.tfvars

# Apply change (requires restart)
terraform apply
```

### Destroy Resources

```bash
# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with: yes
```

---

## 🐛 Troubleshooting

### Quick Diagnostics

```bash
# Check Terraform state
terraform show

# Verify AWS credentials
aws sts get-caller-identity

# Check instance logs
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)

# View CloudWatch logs
aws logs tail /aws/ec2/$(terraform output -raw instance_id) --follow
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Can't SSH | Check security group rules and instance status |
| Key pair not found | Create key pair in correct region |
| Module not found | Check network access to module registry |
| Insufficient capacity | Try different instance type or AZ |

See [ENTERPRISE_MODULE_GUIDE.md](ENTERPRISE_MODULE_GUIDE.md#troubleshooting) for detailed troubleshooting.

---

## 📚 Additional Resources

### Documentation

- **[Complete Deployment Guide](ENTERPRISE_MODULE_GUIDE.md)** - Full documentation
- **[Quick Start Guide](ENTERPRISE_QUICK_START.md)** - Fast deployment
- **[Parameter Reference](../RHEL7_PROVISIONING_PARAMETERS.md)** - All parameters
- **[Example Configuration](terraform.tfvars.enterprise_module.example)** - Template

### External Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Red Hat Enterprise Linux 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/)
- [RedHatProducts Repository](../RedHatProducts/README.md)

---

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Standards

- Use consistent formatting: `terraform fmt`
- Validate configuration: `terraform validate`
- Document all changes
- Follow security best practices
- Add examples for new features

---

## 📋 Changelog

### Version 1.0.0 (2024-11-19)

**Added:**
- Initial enterprise module implementation
- Complete infrastructure setup (VPC, subnet, security groups)
- Comprehensive variable definitions with validation
- Detailed outputs for all resources
- CloudWatch monitoring and alarms
- Elastic IP support
- Production-ready security configuration
- Extensive documentation
- Example configurations for all environments

**Parameters Sourced from RedHatProducts:**
- All instance, networking, storage, and security parameters
- RedHat-specific AMI configuration
- Tagging and metadata structure
- Monitoring recommendations

---

## 📄 License

This configuration is provided as-is for use with the enterprise Terraform module.

---

## 👥 Authors

**DevOps Team**  
Infrastructure as Code Initiative

---

## 🆘 Support

For support:

1. **Documentation**: Review all documentation files
2. **Troubleshooting**: Check [ENTERPRISE_MODULE_GUIDE.md](ENTERPRISE_MODULE_GUIDE.md#troubleshooting)
3. **Logs**: Enable debug logging: `export TF_LOG=DEBUG`
4. **Team**: Contact your DevOps team
5. **RedHatProducts**: Refer to source repository documentation

---

## ✅ Deployment Checklist

Before deploying to production:

- [ ] Reviewed all configuration parameters
- [ ] Created EC2 key pair in target region
- [ ] Restricted SSH access to known IPs
- [ ] Enabled encryption for all volumes
- [ ] Configured appropriate instance type
- [ ] Set up CloudWatch monitoring and alarms
- [ ] Configured backup policy
- [ ] Reviewed and set all tags
- [ ] Tested in non-production environment
- [ ] Documented deployment details
- [ ] Obtained necessary approvals
- [ ] Scheduled maintenance window
- [ ] Prepared rollback plan

---

## 🎯 Key Takeaways

1. **Production-Ready**: Complete infrastructure with security best practices
2. **Enterprise Module**: Uses official module structure with version pinning
3. **RedHatProducts Integration**: All parameters derived from documentation
4. **Flexible Configuration**: Easy customization for any environment
5. **Well-Documented**: Comprehensive guides and examples
6. **Security-First**: Encryption, monitoring, and compliance built-in
7. **Cost-Optimized**: Right-sized defaults with scalability options

---

**Repository**: deployVM  
**Module**: localterraform.com/ag/instance/aws  
**Version**: ~> 3.0  
**OS**: Red Hat Enterprise Linux 7  
**Last Updated**: 2024-11-19

---

*For detailed deployment instructions, see [ENTERPRISE_MODULE_GUIDE.md](ENTERPRISE_MODULE_GUIDE.md)*
