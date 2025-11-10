# RedHat 7 Deployment Guide

## Step-by-Step Deployment Instructions

### Prerequisites Check

Before starting, ensure you have:
- [ ] Terraform installed (version >= 1.0)
- [ ] AWS CLI configured with credentials
- [ ] EC2 key pair created in your target region
- [ ] Your public IP address for SSH restrictions

### Step 1: Prepare AWS Key Pair

If you don't have an EC2 key pair:

```bash
# Create new key pair
aws ec2 create-key-pair \
  --key-name my-redhat-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > my-redhat-key.pem

# Set correct permissions
chmod 400 my-redhat-key.pem
```

### Step 2: Get Your Public IP

For security, restrict SSH access to your IP:

```bash
# Find your public IP
MY_IP=$(curl -s ifconfig.me)
echo "Your IP: $MY_IP"
```

### Step 3: Configure Deployment

Edit `terraform.tfvars` and update:

```hcl
# Replace with your IP for security
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Ensure key name matches your key pair
key_name = "my-redhat-key"

# Adjust instance type if needed
instance_type = "t3.micro"  # or t3.small, t3.medium, etc.
```

### Step 4: Initialize Terraform

```bash
cd /sandbox/deployVM
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 5: Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 6: Review Deployment Plan

```bash
terraform plan
```

Review the resources to be created:
- aws_vpc.main
- aws_internet_gateway.main
- aws_subnet.public
- aws_route_table.public
- aws_route_table_association.public
- aws_security_group.redhat_sg
- aws_instance.redhat7_enhanced

### Step 7: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

Deployment takes approximately 2-3 minutes.

### Step 8: Verify Deployment

```bash
# Check all outputs
terraform output

# Get instance public IP
terraform output instance_public_ip

# Get SSH command
terraform output ssh_connection_command
```

### Step 9: Connect to Instance

```bash
# Get the SSH command (method 1)
SSH_CMD=$(terraform output -raw ssh_connection_command)
eval $SSH_CMD

# Or manually connect (method 2)
PUBLIC_IP=$(terraform output -raw instance_public_ip)
ssh -i my-redhat-key.pem ec2-user@$PUBLIC_IP
```

### Step 10: Verify Instance

Once connected, verify the setup:

```bash
# Check OS version
cat /etc/redhat-release

# Check system resources
free -h
df -h

# Check network connectivity
ping -c 3 google.com

# View deployment log
sudo cat /var/log/deployment.log
```

## Post-Deployment Tasks

### Update System

```bash
sudo yum update -y
```

### Install Additional Software

```bash
# Example: Install common tools
sudo yum install -y \
  git \
  wget \
  curl \
  vim \
  htop \
  tree
```

### Configure Firewall (Optional)

```bash
# Check firewall status
sudo systemctl status firewalld

# Configure if needed
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## Monitoring and Management

### Check Instance Status

```bash
# From your local machine
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'
```

### View Instance Logs

```bash
# Get system log from AWS
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id) \
  --output text
```

### Check Resource Usage

```bash
# On the instance
top
htop  # if installed
iostat
vmstat
```

## Scaling and Modifications

### Change Instance Type

1. Edit `terraform.tfvars`:
   ```hcl
   instance_type = "t3.medium"
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

Note: This will stop and restart the instance.

### Increase Storage

1. Edit `terraform.tfvars`:
   ```hcl
   root_volume_size = 50
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

3. On the instance, extend the filesystem:
   ```bash
   sudo xfs_growfs -d /
   ```

## Troubleshooting

### Issue: Terraform Init Fails

**Solution:**
```bash
# Clear cached providers
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: AWS Credentials Not Found

**Solution:**
```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Issue: SSH Connection Refused

**Solutions:**
1. Wait 2-3 minutes for instance to fully boot
2. Check security group allows your IP
3. Verify key permissions: `chmod 400 my-redhat-key.pem`
4. Check instance is running:
   ```bash
   terraform output instance_state
   ```

### Issue: Key Pair Not Found

**Solution:**
```bash
# List available key pairs
aws ec2 describe-key-pairs --region us-east-1

# Create if missing
aws ec2 create-key-pair \
  --key-name my-redhat-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > my-redhat-key.pem
chmod 400 my-redhat-key.pem
```

## Cleanup

When you're done with the deployment:

### Option 1: Destroy Everything

```bash
terraform destroy
```

Type `yes` when prompted.

### Option 2: Stop Instance (Save Costs)

```bash
# Stop the instance
aws ec2 stop-instances \
  --instance-ids $(terraform output -raw instance_id)

# Start it again later
aws ec2 start-instances \
  --instance-ids $(terraform output -raw instance_id)
```

## Cost Management

### Estimated Monthly Costs (US East)

| Resource | Cost |
|----------|------|
| t3.micro instance | $8.50 |
| 20GB gp3 EBS | $1.60 |
| Data transfer (est.) | $1.00 |
| **Total** | **~$11/month** |

### Tips to Reduce Costs

1. **Stop unused instances**: Stopped instances only incur storage costs
2. **Use smaller instance types**: Start with t3.micro
3. **Clean up when done**: Run `terraform destroy`
4. **Set up billing alerts**: Use AWS CloudWatch billing alarms

## Security Checklist

- [ ] SSH access restricted to specific IP ranges (not 0.0.0.0/0)
- [ ] Root volume encryption enabled
- [ ] Using key-based SSH authentication
- [ ] Security group rules follow least privilege
- [ ] AWS credentials secured (not in code)
- [ ] Key files have proper permissions (400)
- [ ] Regular system updates scheduled

## Next Steps

1. **Application Deployment**: Install and configure your applications
2. **Backup Strategy**: Set up EBS snapshots or AMI creation
3. **Monitoring**: Configure CloudWatch alarms
4. **Automation**: Add CI/CD pipeline for deployments
5. **High Availability**: Consider multi-AZ deployment for production

## Support Resources

- **Terraform Documentation**: https://www.terraform.io/docs
- **AWS EC2 Documentation**: https://docs.aws.amazon.com/ec2/
- **RHEL 7 Documentation**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/
- **Module Repository**: /sandbox/RedHatProducts/README.md