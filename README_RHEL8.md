# RedHat 8 VM Provisioning - Quick Reference

## Overview

This implementation provides production-ready Terraform code for provisioning RedHat Enterprise Linux 8 VMs using the internal module from `localterraform.com/ag/instance/aws`.

## 📁 Files Created

| File | Description |
|------|-------------|
| `rhel8_deployment.tf` | Main Terraform configuration for RHEL 8 deployment |
| `terraform.tfvars.rhel8.example` | Example configuration with all parameters |
| `RHEL8_DEPLOYMENT_GUIDE.md` | Comprehensive deployment guide and documentation |
| `validate_rhel8_deployment.sh` | Pre-deployment validation script |
| `README_RHEL8.md` | This quick reference guide |

## 🚀 Quick Start (3 Steps)

### 1. Configure

```bash
cd /projects/sandbox/deployVM
cp terraform.tfvars.rhel8.example terraform.tfvars
vim terraform.tfvars  # Edit with your values
```

**Minimum required values:**
- `key_name`: Your AWS SSH key pair name
- `allowed_ssh_cidrs`: Your IP address for SSH access

### 2. Validate

```bash
./validate_rhel8_deployment.sh
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## 📋 Implementation Details

### Module Source

The implementation uses the **internal Terraform registry module**:

```hcl
module "redhat8_production" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"
  # ... configuration
}
```

### Required Parameters (All 10)

The module requires all parameters to be explicitly specified:

1. **instance_type** - EC2 instance size (e.g., `t3.medium`)
2. **key_name** - SSH key pair name
3. **subnet_id** - VPC subnet ID (auto-created by main.tf)
4. **security_group_ids** - Security group IDs (auto-created by main.tf)
5. **availability_zone** - AWS AZ (auto-selected from available AZs)
6. **instance_name** - Instance name tag
7. **root_volume_type** - EBS volume type (`gp3` recommended)
8. **root_volume_size** - Volume size in GB
9. **encrypt_root_volume** - Enable encryption (true/false)
10. **tags** - Resource tags (comprehensive set included)

### Infrastructure Created

The deployment provisions:

- ✅ **VPC** (10.0.0.0/16) with DNS support
- ✅ **Public Subnet** (10.0.1.0/24) with auto-assign public IP
- ✅ **Internet Gateway** for outbound connectivity
- ✅ **Route Table** with internet route
- ✅ **Security Group** with SSH (22), HTTP (80), HTTPS (443)
- ✅ **RHEL 8 EC2 Instance** with encrypted EBS volume
- ✅ **Comprehensive tags** for cost allocation and management

### Key Features

🔒 **Security First**
- Encrypted root volume (configurable)
- Restricted SSH access (customize allowed_ssh_cidrs)
- Security groups with defined access rules
- Latest official RHEL 8 AMI from Red Hat

📊 **Production Ready**
- Comprehensive resource tagging
- CloudWatch monitoring compatible
- High availability ready (multi-AZ capable)
- Cost allocation tags included

🎯 **Best Practices**
- Uses gp3 volumes for optimal price/performance
- Follows team naming conventions
- Complete documentation and validation
- Infrastructure as Code with version control

## 🔧 Configuration Examples

### Development Environment

```hcl
instance_type       = "t3.micro"
root_volume_size    = 20
encrypt_root_volume = false  # Optional for dev
environment         = "dev"
```

### Production Environment

```hcl
instance_type       = "t3.medium"
root_volume_size    = 50
encrypt_root_volume = true   # Required for prod
environment         = "prod"
allowed_ssh_cidrs   = ["YOUR_OFFICE_IP/24"]
```

### High-Performance Workload

```hcl
instance_type       = "m5.xlarge"
root_volume_type    = "gp3"
root_volume_size    = 200
encrypt_root_volume = true
environment         = "prod"
```

## 📊 Outputs

The deployment provides comprehensive outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output rhel8_public_ip
terraform output rhel8_ssh_command
terraform output rhel8_deployment_summary
```

Available outputs:
- `rhel8_instance_id` - EC2 instance ID
- `rhel8_public_ip` - Public IP address
- `rhel8_private_ip` - Private IP address
- `rhel8_availability_zone` - Deployment AZ
- `rhel8_ssh_command` - Ready-to-use SSH command
- `rhel8_deployment_summary` - Complete deployment info

## 🔍 Validation & Testing

### Pre-Deployment Validation

```bash
# Run validation script
./validate_rhel8_deployment.sh

# Manual checks
terraform init
terraform validate
terraform fmt -check
terraform plan
```

### Post-Deployment Verification

```bash
# Get instance details
INSTANCE_IP=$(terraform output -raw rhel8_public_ip)
INSTANCE_ID=$(terraform output -raw rhel8_instance_id)

# Wait for instance to be ready
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Test SSH connection
ssh -i ~/.ssh/your-key.pem ec2-user@$INSTANCE_IP

# Verify RHEL version
ssh -i ~/.ssh/your-key.pem ec2-user@$INSTANCE_IP "cat /etc/redhat-release"
# Expected output: Red Hat Enterprise Linux release 8.x
```

## 🏷️ Tagging Strategy

The implementation includes comprehensive tags following organizational standards:

### Core Tags
- `Name` - Instance identifier
- `Environment` - Environment name (dev/staging/prod)
- `Project` - Project name

### Operational Tags
- `OS` - Operating system (RHEL-8)
- `OSVersion` - Full OS version
- `Module` - Terraform module source
- `ManagedBy` - Management tool (Terraform)
- `DeploymentDate` - Timestamp of deployment

### Accountability Tags
- `Owner` - Owning team
- `CostCenter` - Cost allocation
- `Team` - Responsible team

### Compliance Tags
- `Compliance` - Compliance level
- `SecurityLevel` - Security classification
- `DataClass` - Data classification
- `EncryptionEnabled` - Encryption status

### Management Tags
- `BackupPolicy` - Backup schedule
- `MaintenanceWindow` - Maintenance timing
- `MonitoringEnabled` - Monitoring status
- `PatchGroup` - Patching group

## 🔐 Security Best Practices

### ✅ DO

1. **Restrict SSH access**
   ```hcl
   allowed_ssh_cidrs = ["YOUR_IP/32"]
   ```

2. **Enable encryption**
   ```hcl
   encrypt_root_volume = true
   ```

3. **Use secure key permissions**
   ```bash
   chmod 400 your-key.pem
   ```

4. **Regular security updates**
   ```bash
   sudo yum update -y --security
   ```

5. **Configure firewall**
   ```bash
   sudo systemctl enable firewalld
   sudo firewall-cmd --add-service=ssh --permanent
   ```

### ❌ DON'T

1. Don't use 0.0.0.0/0 for SSH in production
2. Don't disable encryption for production workloads
3. Don't commit terraform.tfvars to version control
4. Don't use root user for SSH access
5. Don't skip security updates

## 💰 Cost Estimation

### Monthly Cost (US East Region)

| Component | Size | Monthly Cost |
|-----------|------|--------------|
| t3.micro instance | 2 vCPU, 1 GB | ~$8 |
| t3.medium instance | 2 vCPU, 4 GB | ~$30 |
| m5.large instance | 2 vCPU, 8 GB | ~$70 |
| 20GB gp3 storage | - | ~$2 |
| 50GB gp3 storage | - | ~$5 |
| 100GB gp3 storage | - | ~$10 |

**Example Total Costs:**
- Development (t3.micro + 20GB): **~$10/month**
- Production (t3.medium + 50GB): **~$35/month**
- High-Performance (m5.large + 100GB): **~$80/month**

*Costs are estimates and may vary by region and usage*

## 🛠️ Maintenance Tasks

### Weekly
- Check CloudWatch metrics
- Review security logs
- Monitor disk usage

### Monthly
- Apply security patches: `sudo yum update -y --security`
- Review and optimize costs
- Backup verification
- Access review

### Quarterly
- Full system update: `sudo yum update -y`
- Review and update security groups
- Disaster recovery test
- Documentation update

## 📚 Additional Documentation

- **[RHEL8_DEPLOYMENT_GUIDE.md](RHEL8_DEPLOYMENT_GUIDE.md)** - Comprehensive deployment guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - General deployment guide
- **[README.md](README.md)** - Main repository README

## 🔗 Related Resources

### Internal
- Module source: `localterraform.com/ag/instance/aws`
- RedHatProducts repository: `/projects/sandbox/RedHatProducts`
- Module specification: `RedHatProducts/REDHAT8_MODULE_SPECIFICATION.md`

### External
- [RHEL 8 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🆘 Common Issues

### Issue: "Module not found"
**Solution:** Ensure access to internal Terraform registry (localterraform.com)

### Issue: "Key pair not found"
**Solution:** Create key pair in AWS:
```bash
aws ec2 create-key-pair --key-name my-key \
  --query 'KeyMaterial' --output text > my-key.pem
chmod 400 my-key.pem
```

### Issue: "Cannot connect via SSH"
**Solution:** 
1. Check security group allows your IP
2. Verify key permissions: `chmod 400 key.pem`
3. Use correct username: `ec2-user`
4. Wait for instance to fully boot

### Issue: "Insufficient permissions"
**Solution:** Ensure IAM user/role has EC2 and VPC permissions

## ✅ Checklist for Deployment

- [ ] AWS credentials configured
- [ ] SSH key pair created in AWS
- [ ] terraform.tfvars created and configured
- [ ] SSH access CIDR restricted (not 0.0.0.0/0 for prod)
- [ ] Encryption enabled for production
- [ ] Validation script passed
- [ ] Terraform init completed
- [ ] Terraform plan reviewed
- [ ] Backup strategy defined
- [ ] Monitoring configured
- [ ] Documentation reviewed

## 📞 Support

For issues or questions:
1. Review this documentation
2. Check [RHEL8_DEPLOYMENT_GUIDE.md](RHEL8_DEPLOYMENT_GUIDE.md)
3. Run validation script: `./validate_rhel8_deployment.sh`
4. Check Terraform debug logs: `TF_LOG=DEBUG terraform apply`
5. Contact Platform Engineering team

---

**Quick Commands:**

```bash
# Deploy
terraform init && terraform apply

# Connect
ssh -i your-key.pem ec2-user@$(terraform output -raw rhel8_public_ip)

# Destroy
terraform destroy

# Validate
./validate_rhel8_deployment.sh
```

---

**Version:** 1.0  
**Last Updated:** 2024  
**Repository:** deployVM (agenticguru)
