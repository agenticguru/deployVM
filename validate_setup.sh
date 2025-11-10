#!/bin/bash

# RedHat 7 Deployment - Setup Validation Script
# This script checks prerequisites before deployment

set -e

echo "================================================"
echo "RedHat 7 Deployment - Setup Validation"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((CHECKS_WARNING++))
}

echo "Checking prerequisites..."
echo ""

# Check 1: Terraform installation
echo -n "Checking Terraform installation... "
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n1)
    print_success "Terraform installed: $TERRAFORM_VERSION"
else
    print_error "Terraform not found. Install from: https://www.terraform.io/downloads"
fi

# Check 2: AWS CLI installation
echo -n "Checking AWS CLI installation... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    print_success "AWS CLI installed: $AWS_VERSION"
else
    print_error "AWS CLI not found. Install from: https://aws.amazon.com/cli/"
fi

# Check 3: AWS Credentials
echo -n "Checking AWS credentials... "
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
    AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | cut -d'/' -f2)
    print_success "AWS credentials configured (Account: $AWS_ACCOUNT, User: $AWS_USER)"
else
    print_error "AWS credentials not configured. Run: aws configure"
fi

# Check 4: Terraform files
echo -n "Checking Terraform configuration files... "
if [[ -f "main.tf" && -f "variables.tf" && -f "outputs.tf" ]]; then
    print_success "All required .tf files present"
else
    print_error "Missing Terraform configuration files"
fi

# Check 5: terraform.tfvars
echo -n "Checking terraform.tfvars... "
if [[ -f "terraform.tfvars" ]]; then
    print_success "terraform.tfvars found"
    
    # Check for critical settings
    if grep -q "0.0.0.0/0" terraform.tfvars; then
        print_warning "SSH access set to 0.0.0.0/0 - Consider restricting to your IP"
    fi
else
    print_warning "terraform.tfvars not found. Copy from terraform.tfvars.example"
fi

# Check 6: RedHatProducts module
echo -n "Checking RedHatProducts module... "
if [[ -d "../RedHatProducts/RedHatProducts/modules/redhat7" ]]; then
    print_success "RedHatProducts redhat7 module found"
else
    print_error "RedHatProducts module not found at ../RedHatProducts/"
fi

# Check 7: Key pair (if AWS access available)
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    echo -n "Checking EC2 key pair... "
    KEY_NAME=$(grep 'key_name' terraform.tfvars 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "my-redhat-key")
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
        print_success "Key pair '$KEY_NAME' exists in AWS"
    else
        print_warning "Key pair '$KEY_NAME' not found. Create with: aws ec2 create-key-pair --key-name $KEY_NAME"
    fi
    
    # Check for local key file
    echo -n "Checking local key file... "
    if [[ -f "${KEY_NAME}.pem" || -f "/sandbox/${KEY_NAME}.pem" ]]; then
        print_success "Local key file found"
        KEY_FILE="${KEY_NAME}.pem"
        [[ -f "/sandbox/${KEY_NAME}.pem" ]] && KEY_FILE="/sandbox/${KEY_NAME}.pem"
        
        # Check permissions
        PERMS=$(stat -c "%a" "$KEY_FILE" 2>/dev/null || echo "000")
        if [[ "$PERMS" == "400" || "$PERMS" == "600" ]]; then
            print_success "Key file permissions correct ($PERMS)"
        else
            print_warning "Key file permissions should be 400. Run: chmod 400 $KEY_FILE"
        fi
    else
        print_warning "Local key file not found"
    fi
fi

# Check 8: Terraform initialization
echo -n "Checking Terraform initialization... "
if [[ -d ".terraform" ]]; then
    print_success "Terraform initialized"
else
    print_warning "Terraform not initialized. Run: terraform init"
fi

# Check 9: Region configuration
echo -n "Checking AWS region configuration... "
if [[ -f "terraform.tfvars" ]]; then
    REGION=$(grep 'aws_region' terraform.tfvars 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "us-east-1")
    print_success "AWS region set to: $REGION"
else
    print_warning "Cannot determine AWS region"
fi

# Check 10: Documentation
echo -n "Checking documentation files... "
DOC_COUNT=0
[[ -f "README.md" ]] && ((DOC_COUNT++))
[[ -f "DEPLOYMENT_GUIDE.md" ]] && ((DOC_COUNT++))
[[ -f "QUICK_REFERENCE.md" ]] && ((DOC_COUNT++))
if [[ $DOC_COUNT -ge 2 ]]; then
    print_success "$DOC_COUNT documentation files available"
else
    print_warning "Some documentation files missing"
fi

echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

# Final recommendation
if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ Ready for deployment!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review terraform.tfvars settings"
    echo "  2. Run: terraform init"
    echo "  3. Run: terraform plan"
    echo "  4. Run: terraform apply"
elif [[ $CHECKS_FAILED -le 2 ]]; then
    echo -e "${YELLOW}⚠ Minor issues found. Review failures above.${NC}"
    echo "Fix the issues and run this script again."
else
    echo -e "${RED}✗ Critical issues found. Cannot proceed with deployment.${NC}"
    echo "Please fix the failed checks above before deploying."
    exit 1
fi

echo ""
echo "For help, see:"
echo "  - README.md: Quick start guide"
echo "  - DEPLOYMENT_GUIDE.md: Detailed instructions"
echo "  - QUICK_REFERENCE.md: Command reference"
echo ""
