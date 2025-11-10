# Quick Reference - RedHat 7 Deployment

## Essential Commands

### Initial Setup
```bash
cd /sandbox/deployVM
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### Deploy
```bash
terraform init
terraform plan     # Review changes
terraform apply    # Deploy (type 'yes')
```

### Connect
```bash
# Get SSH command
terraform output ssh_connection_command

# Or connect directly
ssh -i my-redhat-key.pem ec2-user@$(terraform output -raw instance_public_ip)
```

### Manage
```bash
terraform output            # Show all outputs
terraform state list        # List resources
terraform refresh          # Update outputs
terraform show             # Show current state
```

### Cleanup
```bash
terraform destroy          # Remove all resources
```

## Key Files

| File | Purpose |
|------|---------|
| `main.tf` | Infrastructure definition |
| `variables.tf` | Input parameters |
| `outputs.tf` | Result values |
| `terraform.tfvars` | Your configuration |
| `README.md` | Full documentation |
| `DEPLOYMENT_GUIDE.md` | Step-by-step guide |

## Important Settings

### Security (Edit terraform.tfvars)
```hcl
# Replace with your IP!
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Ensure key exists in AWS
key_name = "my-redhat-key"
```

### Instance Size
```hcl
instance_type = "t3.micro"    # $8/month
instance_type = "t3.small"    # $16/month
instance_type = "t3.medium"   # $33/month
```

### Storage
```hcl
root_volume_size = 20         # GB
root_volume_type = "gp3"      # gp2, gp3, io1, io2
encrypt_root_volume = true    # Keep enabled
```

## Quick Troubleshooting

### SSH Connection Issues
1. Wait 2-3 minutes for instance boot
2. Check: `terraform output instance_state`
3. Verify key permissions: `chmod 400 my-redhat-key.pem`
4. Check your IP in `allowed_ssh_cidrs`

### Key Pair Issues
```bash
# Create key if missing
aws ec2 create-key-pair --key-name my-redhat-key --query 'KeyMaterial' --output text > my-redhat-key.pem
chmod 400 my-redhat-key.pem
```

### Find Your IP
```bash
curl -4 ifconfig.me
```

## Resource Names

Default naming pattern: `{project_name}-{environment}-{resource}`

Example with defaults:
- VPC: `redhat-deployment-vpc`
- Instance: `redhat-deployment-dev-redhat7-enhanced`
- Security Group: `redhat-deployment-redhat-*`

## Useful Outputs

```bash
terraform output instance_public_ip     # Connect here
terraform output instance_id           # AWS instance ID
terraform output vpc_id                # Network ID
terraform output deployment_summary    # All key info
```

## Cost Monitoring

Default t3.micro costs ~$10/month:
- Instance: $8.50
- Storage: $1.60

Stop instance to save costs:
```bash
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)
```

## Module Source

Uses RedHat module from:
```
../RedHatProducts/RedHatProducts/modules/redhat7
```

Enhanced with VPC, security groups, and encryption.

## Need Help?

1. Check `README.md` for comprehensive guide
2. Review `DEPLOYMENT_GUIDE.md` for step-by-step instructions
3. See `DEPLOYMENT_SUMMARY.md` for implementation details
4. AWS documentation: https://docs.aws.amazon.com/ec2/
5. Terraform docs: https://www.terraform.io/docs