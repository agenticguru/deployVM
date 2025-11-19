# RedHat 7 EC2 - Enterprise Module Quick Start

## 🚀 Quick Deployment (5 Minutes)

### Prerequisites Checklist

- [ ] AWS account configured
- [ ] Terraform installed (>= 1.0)
- [ ] AWS CLI installed
- [ ] EC2 key pair created

### One-Command Setup

```bash
# Create key pair (if not exists)
aws ec2 create-key-pair --key-name my-redhat-key --query 'KeyMaterial' --output text > my-redhat-key.pem && chmod 400 my-redhat-key.pem

# Create configuration
cp terraform.tfvars.enterprise_module.example terraform.tfvars
sed -i 's/key_name = ".*"/key_name = "my-redhat-key"/' terraform.tfvars

# Deploy
terraform init && terraform apply -auto-approve
```

---

## 📋 Essential Commands

### Deployment

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

### Access Instance

```bash
# Get SSH command
terraform output ssh_connection_command

# Or manually
ssh -i my-redhat-key.pem ec2-user@$(terraform output -raw public_ip)
```

### Quick Status

```bash
# Instance status
terraform output deployment_summary

# Public IP
terraform output public_ip

# Instance ID
terraform output instance_id
```

---

## 🔧 Configuration Templates

### Development

```hcl
# terraform.tfvars
aws_region    = "us-east-1"
environment   = "dev"
instance_type = "t3.micro"
key_name      = "my-key"
root_volume_size = 20
enable_detailed_monitoring = false
```

### Staging

```hcl
# terraform.tfvars
aws_region    = "us-east-1"
environment   = "staging"
instance_type = "t3.medium"
key_name      = "my-key"
root_volume_size = 50
enable_detailed_monitoring = true
enable_cloudwatch_alarms = true
allowed_ssh_cidrs = ["10.0.0.0/8"]
```

### Production

```hcl
# terraform.tfvars
aws_region    = "us-east-1"
environment   = "prod"
instance_type = "m5.large"
key_name      = "prod-key"
root_volume_size = 100
root_volume_type = "gp3"
encrypt_root_volume = true
enable_detailed_monitoring = true
enable_cloudwatch_alarms = true
create_elastic_ip = true
allowed_ssh_cidrs = ["10.0.0.0/8"]
backup_policy = "daily"
```

---

## 📊 Module Parameters

### Required

| Parameter | Description | Example |
|-----------|-------------|---------|
| `key_name` | EC2 key pair name | "my-redhat-key" |

### Most Common

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `instance_type` | t3.micro | Compute resources |
| `root_volume_size` | 20 | Storage in GB |
| `root_volume_type` | gp3 | Storage type |
| `encrypt_root_volume` | true | Encryption |
| `allowed_ssh_cidrs` | ["0.0.0.0/0"] | SSH access control |

### All Parameters

See `variables_enterprise_module.tf` for complete list.

---

## 🔐 Security Quick Wins

### Restrict SSH Access

```hcl
# Get your IP
allowed_ssh_cidrs = ["$(curl -s https://api.ipify.org)/32"]
```

### Enable Production Security

```hcl
encrypt_root_volume = true
enable_cloudwatch_alarms = true
security_level = "Confidential"
```

### Post-Deployment Hardening

```bash
# Update system
ssh ec2-user@<ip> 'sudo yum update -y'

# Enable firewall
ssh ec2-user@<ip> 'sudo systemctl enable firewalld && sudo systemctl start firewalld'
```

---

## 💰 Cost Estimates

| Environment | Instance | Storage | Monthly |
|-------------|----------|---------|---------|
| Dev | t3.micro | 20 GB | ~$10 |
| Staging | t3.medium | 50 GB | ~$38 |
| Production | m5.large | 100 GB | ~$90 |

---

## 🐛 Common Issues

### Can't SSH

```bash
# Check security group
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# Check instance status
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# Get console output
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)
```

### Key Pair Not Found

```bash
# List key pairs
aws ec2 describe-key-pairs

# Create new one
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
chmod 400 my-key.pem
```

### Module Not Found

```bash
# Clear cache and re-init
rm -rf .terraform .terraform.lock.hcl
terraform init
```

---

## 📚 Module Structure

```
module "vm_example_rh7" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 3.0"
  
  # Core
  instance_type = var.instance_type
  key_name      = var.key_name
  instance_name = "${var.project_name}-${var.environment}-redhat7"
  
  # Network
  subnet_id              = aws_subnet.public.id
  security_group_ids     = [aws_security_group.sg.id]
  availability_zone      = data.aws_availability_zones.available.names[0]
  
  # Storage
  root_volume_type    = var.root_volume_type
  root_volume_size    = var.root_volume_size
  encrypt_root_volume = var.encrypt_root_volume
  
  # Tags
  tags = merge(var.common_tags, {...})
}
```

---

## 🔄 Update Workflow

```bash
# 1. Update configuration
vi terraform.tfvars

# 2. Format
terraform fmt

# 3. Validate
terraform validate

# 4. Plan
terraform plan -out=tfplan

# 5. Review plan
# Check what will change

# 6. Apply
terraform apply tfplan

# 7. Verify
terraform output deployment_summary
```

---

## 📦 Files Reference

| File | Purpose |
|------|---------|
| `rhel7_enterprise_module.tf` | Main configuration |
| `variables_enterprise_module.tf` | Variable definitions |
| `outputs_enterprise.tf` | Output definitions |
| `terraform.tfvars` | Your configuration values |
| `ENTERPRISE_MODULE_GUIDE.md` | Full documentation |

---

## 🎯 Next Steps

1. **Deploy**: Follow quick deployment above
2. **Access**: SSH to instance
3. **Secure**: Restrict SSH access
4. **Configure**: Install your application
5. **Monitor**: Enable CloudWatch alarms
6. **Backup**: Configure AWS Backup
7. **Document**: Update project documentation

---

## 📞 Support

- **Documentation**: `ENTERPRISE_MODULE_GUIDE.md`
- **Parameters**: `RHEL7_PROVISIONING_PARAMETERS.md`
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **RHEL Docs**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/

---

## ✅ Post-Deployment Checklist

- [ ] Instance is running
- [ ] Can SSH to instance
- [ ] System updated (`yum update -y`)
- [ ] Security group restricted
- [ ] Firewall configured
- [ ] Monitoring enabled
- [ ] Backups configured
- [ ] Documentation updated
- [ ] Team notified

---

**Quick Reference Version:** 1.0  
**Module:** localterraform.com/ag/instance/aws ~> 3.0  
**OS:** RedHat Enterprise Linux 7
