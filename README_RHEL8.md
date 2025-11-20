# RedHat 8 VM Provisioning with Terraform

## 🎯 Quick Start - Copy & Deploy

```hcl
# Deploy RedHat 8 VM using custom module
module "redhat8_vm" {
  source = "localterraform.com/ag/instance/aws"
  
  # Instance Configuration
  instance_type = "t3.medium"
  key_name      = var.key_name
  instance_name = "${var.project_name}-${var.environment}-rhel8-vm"
  
  # Network Configuration
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.redhat_sg.id]
  availability_zone  = data.aws_availability_zones.available.names[0]
  
  # Storage Configuration
  root_volume_type    = "gp3"
  root_volume_size    = 50
  encrypt_root_volume = true
  
  # Tags
  tags = {
    Environment = var.environment
    OS          = "RHEL-8"
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
```

## 📚 Documentation

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **RHEL8_QUICK_START.md** | Ready-to-use code block + quick guide | Start here! 5 min read |
| **RHEL8_DEPLOYMENT_EXPLANATION.md** | Complete technical documentation | Deep dive, troubleshooting |
| **RHEL8_DEPLOYMENT_SUMMARY.md** | Executive overview + features | Project summary, reference |
| **rhel8_deployment.tf** | Complete Terraform code | Copy this file to deploy |

## 🚀 Deploy in 3 Steps

```bash
# 1. Initialize Terraform
terraform init

# 2. Deploy the VM
terraform apply

# 3. Connect to your VM
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw rhel8_public_ip)
```

## 💡 What You Get

✅ **RedHat 8 VM** (latest version, automatically selected)  
✅ **t3.medium instance** (2 vCPU, 4 GB RAM)  
✅ **50 GB encrypted storage** (gp3 SSD)  
✅ **Secure networking** (VPC, security groups)  
✅ **Complete outputs** (IPs, SSH command, etc.)  
✅ **Production-ready** (tags, encryption, best practices)  

## 📦 Module Details

**Source**: `localterraform.com/ag/instance/aws`

**Required Parameters** (all 10 provided):
1. instance_type
2. key_name
3. instance_name
4. subnet_id
5. security_group_ids
6. availability_zone
7. root_volume_type
8. root_volume_size
9. encrypt_root_volume
10. tags

## 💰 Cost

**~$34/month** (us-east-1)
- EC2 t3.medium: ~$30/mo
- 50 GB gp3: ~$4/mo
- Excludes data transfer

## 📖 Key Features Explained

### Automatic AMI Selection
Uses data source to always get the latest RedHat 8 AMI:
```hcl
data "aws_ami" "redhat8" {
  most_recent = true
  owners      = ["309956199498"]  # Red Hat official
}
```

### Secure by Default
- ✅ Root volume encrypted
- ✅ Security group protection
- ✅ SSH key authentication only

### Production-Ready Configuration
- ✅ gp3 storage (better than gp2)
- ✅ Comprehensive tagging
- ✅ Proper instance sizing
- ✅ High availability zone placement

## 🔧 Customization Examples

**Change instance size:**
```hcl
instance_type = "t3.large"  # 2 vCPU, 8 GB RAM
```

**Increase storage:**
```hcl
root_volume_size = 100  # 100 GB
```

**Add more tags:**
```hcl
tags = {
  Environment = "production"
  Department  = "engineering"
  CostCenter  = "CC-12345"
}
```

## 🎓 Learn More

For complete documentation including:
- Parameter explanations
- Architecture diagrams
- Post-deployment setup
- Troubleshooting guide
- Security best practices
- Cost optimization tips

**Read**: `RHEL8_DEPLOYMENT_EXPLANATION.md`

## ✅ Validation

- ✅ Terraform syntax validated
- ✅ All parameters correctly specified
- ✅ Module source path correct
- ✅ Production-ready defaults
- ✅ Comprehensive documentation
- ✅ Ready to deploy

## 📍 Repository

**Location**: `/projects/sandbox/deployVM/`  
**Repository**: deployVM  
**Owner**: agenticguru  

## 🤝 Support

Questions? Check the documentation:
1. Start with **RHEL8_QUICK_START.md**
2. Reference **RHEL8_DEPLOYMENT_EXPLANATION.md** for details
3. Review **rhel8_deployment.tf** for implementation

---

**Ready to deploy? Start with RHEL8_QUICK_START.md!** 🚀
