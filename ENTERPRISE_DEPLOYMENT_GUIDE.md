# Terraform Enterprise Module Deployment Guide
## Red Hat 7 EC2 Instance Provisioning

---

## Document Purpose

This guide provides comprehensive instructions for deploying Red Hat Enterprise Linux 7 (RHEL 7) EC2 instances using the internal Terraform Enterprise module at `localterraform.com/ag/instance/aws`. All configurations are based on parameters gathered from the **RedHatProducts** repository documentation.

---

## Files Created

The following files have been created in the `deployVM` repository to support enterprise module deployment:

### Core Configuration Files

1. **rhel7_enterprise.tf**
   - Main Terraform configuration using the enterprise module
   - Standalone deployment configuration
   - AMI data source definitions
   - Complete module parameter configuration

2. **variables_enterprise.tf**
   - All variable definitions for enterprise deployment
   - Parameter validation rules
   - Default values and documentation
   - Instance type selection guide
   - Storage configuration guide

3. **outputs_enterprise.tf**
   - Comprehensive output definitions
   - Instance information outputs
   - Network and connectivity details
   - SSH connection information
   - Deployment summary
   - Cost estimation outputs
   - Post-deployment next steps

### Example and Documentation Files

4. **terraform.tfvars.enterprise.example**
   - Example configuration file
   - Detailed parameter explanations
   - Configuration examples by use case
   - Security recommendations
   - Cost estimates

5. **README_ENTERPRISE.md**
   - Complete documentation for enterprise deployment
   - Quick start guide
   - Configuration reference
   - Usage examples
   - Security best practices
   - Troubleshooting guide
   - Cost estimation

6. **rhel7_enterprise_integrated.tf**
   - Advanced integration example
   - Multi-instance deployment patterns
   - Load balancer configuration
   - CloudWatch alarms setup
   - High availability configuration

7. **ENTERPRISE_DEPLOYMENT_GUIDE.md** (this file)
   - Overview of all created files
   - Quick start instructions
   - Deployment scenarios
   - Migration guide

---

## Quick Start Guide

### Step 1: Understand Your Deployment Scenario

Choose one of the following scenarios:

#### Scenario A: Standalone Enterprise Deployment
Use `rhel7_enterprise.tf` for a simple, standalone RHEL 7 instance using the enterprise module.

**Best for:**
- New projects
- Simple deployments
- Single instance requirements

#### Scenario B: Integrated Deployment
Use `rhel7_enterprise_integrated.tf` to integrate with existing VPC infrastructure.

**Best for:**
- Existing deployVM infrastructure
- Multi-instance deployments
- High availability setups
- Load balanced configurations

### Step 2: Prepare Your Environment

```bash
# Navigate to deployVM directory
cd /sandbox/deployVM

# Verify AWS credentials
aws sts get-caller-identity

# Create EC2 key pair
aws ec2 create-key-pair \
  --key-name my-rhel7-key \
  --query 'KeyMaterial' \
  --output text > my-rhel7-key.pem

chmod 400 my-rhel7-key.pem
```

### Step 3: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.enterprise.example terraform.tfvars

# Edit configuration
vim terraform.tfvars
```

Minimum required configuration:
```hcl
enterprise_instance_type = "t3.micro"
enterprise_key_name      = "my-rhel7-key"
project_name             = "my-project"
environment              = "dev"
aws_region               = "us-east-1"
```

### Step 4: Deploy

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply configuration
terraform apply

# Get connection details
terraform output enterprise_ssh_connection_command
```

---

## Deployment Scenarios

### Scenario 1: Development Instance

**Goal:** Deploy a minimal cost development instance

**Configuration:**
```hcl
# terraform.tfvars
enterprise_instance_type        = "t3.micro"
enterprise_key_name             = "dev-key"
enterprise_instance_name        = "dev-rhel7-test"
enterprise_root_volume_size     = 20
enterprise_encrypt_root_volume  = false
enterprise_enable_monitoring    = false

environment = "dev"
project_name = "my-project"
```

**Monthly Cost:** ~$10

**Use Case:** Testing, development, learning

---

### Scenario 2: Production Single Instance

**Goal:** Deploy a production-ready single instance

**Configuration:**
```hcl
# terraform.tfvars
enterprise_instance_type            = "t3.medium"
enterprise_key_name                 = "prod-key"
enterprise_instance_name            = "prod-app-rhel7"
enterprise_root_volume_type         = "gp3"
enterprise_root_volume_size         = 50
enterprise_encrypt_root_volume      = true
enterprise_enable_monitoring        = true
enterprise_disable_api_termination  = true

enterprise_common_tags = {
  Environment = "production"
  Backup      = "daily"
  Monitoring  = "enabled"
}

environment = "production"
project_name = "my-app"
```

**Monthly Cost:** ~$37

**Use Case:** Small production applications, web servers

---

### Scenario 3: High Availability Setup

**Goal:** Deploy multiple instances with load balancing

**Files to use:**
- `rhel7_enterprise_integrated.tf`
- `variables_enterprise.tf`
- `outputs_enterprise.tf`

**Configuration:**
```hcl
# terraform.tfvars
enterprise_instance_type            = "t3.medium"
enterprise_key_name                 = "prod-key"
enterprise_root_volume_type         = "gp3"
enterprise_root_volume_size         = 50
enterprise_encrypt_root_volume      = true
enterprise_enable_monitoring        = true

# Enable HA features
enable_secondary_instance = true
enable_load_balancer      = true
enable_monitoring_alarms  = true

environment = "production"
project_name = "ha-app"
```

**Monthly Cost:** ~$80+ (2 instances + load balancer)

**Use Case:** Critical applications requiring high availability

---

### Scenario 4: Database Server

**Goal:** Deploy a memory-optimized instance for database workload

**Configuration:**
```hcl
# terraform.tfvars
enterprise_instance_type            = "r5.large"
enterprise_key_name                 = "db-key"
enterprise_instance_name            = "prod-db-rhel7"
enterprise_root_volume_type         = "io2"
enterprise_root_volume_size         = 200
enterprise_encrypt_root_volume      = true
enterprise_enable_monitoring        = true
enterprise_ebs_optimized            = true
enterprise_disable_api_termination  = true

enterprise_user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y postgresql-server postgresql-contrib
  postgresql-setup initdb
  systemctl enable postgresql
  systemctl start postgresql
EOF

environment = "production"
project_name = "database"
```

**Monthly Cost:** ~$120+

**Use Case:** PostgreSQL, MySQL, other database servers

---

## Parameters Reference

### Parameters from RedHatProducts Documentation

All parameters are based on the RedHatProducts repository documentation:

#### Required Parameters (from RedHatProducts/README.md - RHEL 7 Module)

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `instance_type` | string | RedHatProducts Variables | EC2 instance type (default: t3.micro) |
| `key_name` | string | RedHatProducts Variables | SSH key pair name |

#### Optional Parameters (from RedHatProducts/README.md)

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `instance_name` | string | RedHatProducts Variables | Instance name tag (default: redhat7-instance) |

#### Enhanced Parameters (from RedHatProducts/README.md - RHEL 8 Module)

Additional parameters gathered from the more advanced RHEL 8 module documentation:

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `subnet_id` | string | RedHatProducts RHEL 8 | VPC subnet ID |
| `security_group_ids` | list(string) | RedHatProducts RHEL 8 | Security group IDs |
| `availability_zone` | string | RedHatProducts RHEL 8 | Availability zone |
| `root_volume_type` | string | RedHatProducts RHEL 8 | Volume type (gp2/gp3/io1/io2) |
| `root_volume_size` | number | RedHatProducts RHEL 8 | Volume size in GB |
| `encrypt_root_volume` | bool | RedHatProducts RHEL 8 | Enable encryption |
| `tags` | map(string) | RedHatProducts RHEL 8 | Resource tags |

#### AMI Information (from RedHatProducts/README.md)

| Property | Value | Source |
|----------|-------|--------|
| **Owner ID** | 309956199498 | RedHatProducts README |
| **Naming Pattern** | RHEL-7.*-x86_64-* | RedHatProducts README |
| **Architecture** | x86_64 | RedHatProducts README |

---

## Parameter Mapping

### From RedHatProducts to Enterprise Module

The parameters are mapped as follows:

```hcl
# RedHatProducts RHEL 7 Module Parameters
module "redhat7_instance" {
  source = "../RedHatProducts/RedHatProducts/modules/redhat7"
  
  instance_type = var.instance_type  # REQUIRED from RedHatProducts
  key_name      = var.key_name       # REQUIRED from RedHatProducts
  instance_name = var.instance_name  # OPTIONAL from RedHatProducts
}

# Terraform Enterprise Module with Enhanced Parameters
module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"
  
  # Core parameters from RedHatProducts RHEL 7
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name
  instance_name = var.enterprise_instance_name
  
  # Enhanced parameters from RedHatProducts RHEL 8
  subnet_id              = var.enterprise_subnet_id
  security_group_ids     = var.enterprise_security_group_ids
  availability_zone      = var.enterprise_availability_zone
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume
  tags                   = var.enterprise_common_tags
}
```

---

## Migration Guide

### From Existing deployVM Setup

If you're currently using the local RedHatProducts module and want to migrate to the enterprise module:

#### Step 1: Backup Current State

```bash
# Backup current terraform state
cp terraform.tfstate terraform.tfstate.backup

# Export current configuration
terraform show > current-config.txt
```

#### Step 2: Choose Migration Strategy

**Option A: Parallel Deployment**
Deploy enterprise instances alongside existing ones:

1. Use `rhel7_enterprise.tf` with different resource names
2. Test enterprise deployment
3. Migrate traffic/workload
4. Decommission old instances

**Option B: In-Place Migration**
Replace existing instances with enterprise module:

1. Document current instance configurations
2. Note IP addresses and DNS names
3. Deploy new enterprise instances
4. Update DNS/load balancer
5. Destroy old instances

#### Step 3: Update Variable Names

```hcl
# Old (local module)
instance_type = "t3.micro"
key_name      = "my-key"
instance_name = "my-instance"

# New (enterprise module)
enterprise_instance_type = "t3.micro"
enterprise_key_name      = "my-key"
enterprise_instance_name = "my-instance"
```

#### Step 4: Test and Validate

```bash
# Test enterprise configuration
terraform plan -target=module.rhel7_enterprise_instance

# Apply only enterprise resources
terraform apply -target=module.rhel7_enterprise_instance

# Validate deployment
terraform output enterprise_deployment_summary
```

---

## Best Practices Checklist

### Security

- [ ] Use specific CIDR ranges for SSH access (not 0.0.0.0/0)
- [ ] Enable root volume encryption
- [ ] Store key pairs securely (not in version control)
- [ ] Use IAM instance profiles instead of access keys
- [ ] Enable termination protection for production
- [ ] Review and minimize security group rules
- [ ] Enable CloudWatch logging
- [ ] Implement regular backup strategy

### Configuration

- [ ] Use appropriate instance types for workload
- [ ] Set proper volume sizes
- [ ] Configure user data for initialization
- [ ] Apply comprehensive tagging strategy
- [ ] Document instance purpose and ownership
- [ ] Set proper environment labels
- [ ] Configure monitoring and alarms

### Operations

- [ ] Test deployment in dev before production
- [ ] Document configuration decisions
- [ ] Set up monitoring and alerting
- [ ] Configure backup procedures
- [ ] Plan for disaster recovery
- [ ] Implement cost tracking
- [ ] Schedule regular updates and patches
- [ ] Document SSH access procedures

### Cost Optimization

- [ ] Right-size instances based on actual usage
- [ ] Use gp3 volumes instead of gp2
- [ ] Stop non-production instances when not in use
- [ ] Review and remove unused resources
- [ ] Use Reserved Instances for long-term workloads
- [ ] Monitor and optimize data transfer costs
- [ ] Review CloudWatch metrics and alarms

---

## Troubleshooting Common Issues

### Issue: Module Source Not Found

**Symptom:** "Module not found: localterraform.com/ag/instance/aws"

**Solutions:**
1. Verify Terraform Enterprise access
2. Check VPN/network connectivity
3. Authenticate: `terraform login localterraform.com`
4. Verify module name spelling
5. Check module version constraint

### Issue: Parameter Not Recognized

**Symptom:** "An argument named 'xxx' is not expected here"

**Solutions:**
1. Check module documentation for supported parameters
2. Verify parameter name spelling
3. Check module version compatibility
4. Some parameters may be module-specific

### Issue: AMI Not Available in Region

**Symptom:** "InvalidAMIID.NotFound" or no AMI returned

**Solutions:**
```bash
# Check available AMIs in your region
aws ec2 describe-images \
  --region us-east-1 \
  --owners 309956199498 \
  --filters "Name=name,Values=RHEL-7.*-x86_64-*"
```

### Issue: Insufficient Instance Capacity

**Symptom:** "InsufficientInstanceCapacity" error

**Solutions:**
1. Try different availability zone
2. Try different instance type
3. Wait and retry (capacity issues are often temporary)
4. Contact AWS support for capacity issues

---

## Additional Resources

### Documentation References

1. **RedHatProducts Repository**
   - Location: `/sandbox/RedHatProducts/`
   - README: `/sandbox/RedHatProducts/README.md`
   - RHEL 7 Module: `/sandbox/RedHatProducts/RedHatProducts/modules/redhat7/`

2. **Research Document**
   - Location: `/sandbox/terraform_enterprise_module_research.md`
   - Complete parameter documentation
   - Usage examples and best practices

3. **AWS Documentation**
   - [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
   - [EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
   - [VPC Documentation](https://docs.aws.amazon.com/vpc/)

4. **Red Hat Documentation**
   - [RHEL 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7)
   - [RHEL on AWS](https://access.redhat.com/articles/2962171)

### Terraform Commands Quick Reference

```bash
# Initialization and validation
terraform init
terraform validate
terraform fmt

# Planning and applying
terraform plan
terraform plan -out=tfplan
terraform apply
terraform apply tfplan

# Outputs and state
terraform output
terraform output enterprise_deployment_summary
terraform show
terraform state list

# Targeted operations
terraform plan -target=module.rhel7_enterprise_instance
terraform apply -target=module.rhel7_enterprise_instance

# Cleanup
terraform destroy
terraform destroy -target=module.rhel7_enterprise_instance
```

### AWS CLI Commands Quick Reference

```bash
# Key pair management
aws ec2 describe-key-pairs
aws ec2 create-key-pair --key-name my-key
aws ec2 delete-key-pair --key-name my-key

# Instance management
aws ec2 describe-instances
aws ec2 start-instances --instance-ids i-xxxxx
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 terminate-instances --instance-ids i-xxxxx

# AMI queries
aws ec2 describe-images --owners 309956199498

# Network queries
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-security-groups
```

---

## Support and Maintenance

### Getting Help

1. **Review Documentation**
   - Start with README_ENTERPRISE.md
   - Check troubleshooting sections
   - Review example configurations

2. **Check Logs**
   - Terraform output
   - CloudWatch logs
   - EC2 system logs

3. **Contact Support**
   - Internal infrastructure team
   - Terraform Enterprise support
   - AWS support

### Reporting Issues

When reporting issues, include:

- Terraform version
- Module version
- Error messages (full output)
- Configuration files (sanitized)
- Steps to reproduce
- Expected vs actual behavior

### Contributing

To contribute improvements:

1. Test changes in development environment
2. Document new features or changes
3. Update relevant documentation files
4. Submit for review
5. Follow organizational change management procedures

---

## Conclusion

This deployment guide provides everything needed to provision RHEL 7 EC2 instances using the Terraform Enterprise module. All configurations are based on parameters documented in the RedHatProducts repository.

For questions or assistance:
- Review the comprehensive documentation in README_ENTERPRISE.md
- Check the example configurations in terraform.tfvars.enterprise.example
- Refer to the parameter research document
- Contact the infrastructure team

**Happy deploying!** 🚀

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Maintained By:** Infrastructure Team  
**Repository:** deployVM
