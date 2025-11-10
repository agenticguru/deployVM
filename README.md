# RedHat 7 EC2 Deployment

This repository deploys RedHat Enterprise Linux 7 EC2 instances using Terraform modules from the RedHatProducts repository.

## Features

- **Complete Infrastructure**: VPC, subnet, security group, and EC2 instance
- **Security**: Encrypted volumes, configurable SSH access, security groups
- **Module Integration**: Uses redhat7 module from RedHatProducts repository
- **Flexibility**: Configurable instance types, storage, and networking

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnet (10.0.1.0/24)
│   └── RedHat 7 EC2 Instance
│       ├── Public IP
│       ├── Security Group (SSH/HTTP/HTTPS)
│       └── Encrypted EBS Volume
└── Internet Gateway
```

## Quick Start

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region = "us-east-1"
project_name = "my-redhat-project"
key_name = "my-redhat-key"
instance_type = "t3.micro"
allowed_ssh_cidrs = ["YOUR_IP/32"]  # Replace with your IP
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Connect

```bash
# Get connection command
terraform output ssh_connection_command

# Connect to instance
ssh -i my-redhat-key.pem ec2-user@<PUBLIC_IP>
```

## Configuration

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region |
| `instance_type` | t3.micro | EC2 instance type |
| `key_name` | my-redhat-key | AWS key pair name |
| `root_volume_size` | 20 | Root volume size (GB) |
| `encrypt_root_volume` | true | Enable volume encryption |
| `allowed_ssh_cidrs` | ["0.0.0.0/0"] | SSH access CIDRs |

### Instance Types

| Type | vCPUs | Memory | Use Case |
|------|-------|--------|----------|
| t3.micro | 2 | 1 GB | Development |
| t3.small | 2 | 2 GB | Small apps |
| t3.medium | 2 | 4 GB | Medium workloads |
| m5.large | 2 | 8 GB | Production |

## Module Integration

This deployment integrates the redhat7 module:

```hcl
module "redhat7_instance" {
  source = "../RedHatProducts/RedHatProducts/modules/redhat7"
  
  instance_type = var.instance_type
  key_name      = var.key_name
  instance_name = "${var.project_name}-${var.environment}-redhat7"
}
```

Enhanced features include:
- VPC and networking infrastructure
- Security group configuration
- Encrypted storage
- Custom user data
- Comprehensive outputs

## Security Best Practices

1. **Restrict SSH Access**: Use specific IP ranges instead of `0.0.0.0/0`
2. **Use Key Authentication**: Ensure proper key pair setup
3. **Enable Encryption**: Keep `encrypt_root_volume = true`
4. **Regular Updates**: Run `sudo yum update -y` on instances
5. **Network Segmentation**: Consider private subnets for production

## Outputs

The deployment provides:
- Instance ID and IP addresses
- VPC and network resource IDs
- SSH connection command
- AMI information
- Deployment summary

## Troubleshooting

### Key Pair Issues
```bash
# Check if key exists
aws ec2 describe-key-pairs --key-names my-redhat-key

# Create new key pair
aws ec2 create-key-pair --key-name my-redhat-key --query 'KeyMaterial' --output text > my-redhat-key.pem
chmod 400 my-redhat-key.pem
```

### SSH Connection Issues
1. Check security group allows your IP
2. Verify key permissions: `chmod 400 key.pem`
3. Wait for instance to fully boot
4. Use correct username: `ec2-user`

## Cleanup

```bash
terraform destroy
```

## Cost Estimate

Monthly cost (US East):
- t3.micro instance: ~$8
- 20GB gp3 storage: ~$2
- **Total: ~$10/month**

## Related Documentation

- [RedHatProducts Module](../RedHatProducts/README.md)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)