# Red Hat 7 EC2 Provisioning with Terraform Enterprise Module

## Overview

This implementation provisions Red Hat Enterprise Linux 7 EC2 instances using the internal Terraform Enterprise module at `localterraform.com/ag/instance/aws`, configured with parameters gathered from the RedHatProducts repository documentation.

## Module Integration

### Source Configuration
```hcl
module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"
  
  # Configuration based on RedHatProducts parameters
  ami_id        = data.aws_ami.rhel7_enterprise.id
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name
  # ... additional parameters
}
```

### Parameters from RedHatProducts Repository

Based on RedHatProducts documentation analysis:

#### AMI Selection (from RedHatProducts/modules/redhat7):
- **Owner**: 309956199498 (Official Red Hat AWS Account)
- **Filter**: RHEL-7.*-x86_64-*
- **Architecture**: x86_64

#### Required Parameters:
- `instance_type`: Default t3.micro (customizable)
- `key_name`: SSH key pair for access
- `instance_name`: Naming convention support

#### Enhanced Parameters (from RHEL8 module):
- `subnet_id`: VPC subnet integration
- `security_group_ids`: Security group attachment
- `availability_zone`: AZ specification
- `root_volume_type`: EBS volume type (gp2, gp3, io1, io2)
- `root_volume_size`: Minimum 10GB, recommended 20GB+
- `encrypt_root_volume`: Security compliance

## Quick Start

### 1. Basic Configuration
```hcl
# terraform.tfvars
enterprise_key_name              = "my-rhel-key"
enterprise_instance_type         = "t3.medium"
enterprise_root_volume_type      = "gp3"
enterprise_root_volume_size      = 50
enterprise_encrypt_root_volume   = true
enterprise_enable_monitoring     = true
```

### 2. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Instance
```bash
terraform output rhel7_enterprise_ssh_command
```

## Key Features

- **Official Red Hat AMIs**: Automatically selects latest RHEL 7 x86_64
- **Enterprise Module Integration**: Uses internal Terraform Enterprise module
- **Security**: Encrypted EBS volumes, IMDSv2 enforcement
- **High Availability**: Optional multi-AZ deployment
- **Monitoring**: CloudWatch integration
- **Flexible Configuration**: Comprehensive parameter customization

## Configuration Options

### Production Setup
```hcl
enterprise_instance_type           = "m5.large"
enterprise_disable_api_termination = true
enterprise_allocate_eip            = true
enable_ha_deployment              = true
enable_cloudwatch_logs            = true
```

### High Availability
```hcl
enable_ha_deployment           = true
enterprise_subnet_id_secondary = "subnet-different-az"
```

## Security Best Practices

1. **Encryption**: Always enable root volume encryption
2. **Network**: Use private subnets when possible
3. **Access**: Restrict SSH to specific IP ranges
4. **Monitoring**: Enable detailed CloudWatch monitoring
5. **IAM**: Use instance profiles with minimal permissions

## Outputs

```hcl
rhel7_enterprise_primary = {
  instance_id       = "i-0123456789abcdef0"
  public_ip         = "203.0.113.10"
  private_ip        = "10.0.1.50"
  availability_zone = "us-east-1a"
  # ... additional details
}
```

## Cost Estimate

**Single Instance (t3.medium)**:
- EC2 Instance: ~$30/month
- 50GB gp3 Storage: ~$5/month
- Total: ~$35/month

**High Availability (2x t3.medium)**:
- Total: ~$70/month

## Implementation Details

This implementation leverages:

1. **RedHatProducts Repository Knowledge**:
   - AMI selection criteria from redhat7 module
   - Parameter patterns from redhat8 module
   - Security and storage best practices

2. **Terraform Enterprise Module**:
   - Internal module at localterraform.com/ag/instance/aws
   - Enterprise-grade features and support
   - Advanced configuration options

3. **Enhanced Features**:
   - Multi-AZ high availability support
   - Elastic IP allocation
   - CloudWatch logging integration
   - Comprehensive tagging strategy

## Troubleshooting

### Common Issues:
1. **Module Access**: Verify Terraform Enterprise connectivity
2. **AMI Availability**: Ensure Red Hat AMIs are accessible
3. **Permissions**: Check IAM permissions for EC2 operations
4. **Network**: Verify VPC and subnet configuration

For detailed troubleshooting, see the complete documentation in the repository.
