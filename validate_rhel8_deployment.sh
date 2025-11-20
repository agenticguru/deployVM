#!/bin/bash
# ============================================================================
# RedHat 8 Deployment Validation Script
# ============================================================================
# This script validates the RedHat 8 deployment configuration and readiness
# Run before terraform apply to catch common configuration issues
# ============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}\n"
}

print_check() {
    echo -e "${YELLOW}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((CHECKS_WARNING++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# ============================================================================
# Validation Checks
# ============================================================================

print_header "RedHat 8 Deployment Validation"

# 1. Check Terraform installation
print_check "Checking Terraform installation..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    print_pass "Terraform installed (version: $TERRAFORM_VERSION)"
else
    print_fail "Terraform is not installed"
fi

# 2. Check Terraform version
print_check "Checking Terraform version compatibility..."
if command -v terraform &> /dev/null; then
    VERSION_CHECK=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 | cut -d'.' -f1)
    if [ "$VERSION_CHECK" -ge 1 ]; then
        print_pass "Terraform version is compatible (>= 1.0)"
    else
        print_fail "Terraform version is too old (< 1.0)"
    fi
fi

# 3. Check AWS CLI installation
print_check "Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    print_pass "AWS CLI installed (version: $AWS_VERSION)"
else
    print_warn "AWS CLI is not installed (optional but recommended)"
fi

# 4. Check AWS credentials
print_check "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
    print_pass "AWS credentials configured"
    print_info "Account: $AWS_ACCOUNT"
    print_info "User/Role: $AWS_USER"
else
    print_fail "AWS credentials not configured or invalid"
fi

# 5. Check for terraform.tfvars file
print_check "Checking for terraform.tfvars configuration..."
if [ -f "terraform.tfvars" ]; then
    print_pass "terraform.tfvars file exists"
else
    print_warn "terraform.tfvars not found - using defaults or will prompt"
    print_info "Run: cp terraform.tfvars.rhel8.example terraform.tfvars"
fi

# 6. Check for required files
print_check "Checking for required Terraform files..."
REQUIRED_FILES=("rhel8_deployment.tf" "main.tf" "variables.tf" "outputs.tf")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_info "Found: $file"
    else
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    print_pass "All required Terraform files present"
else
    print_fail "Missing files: ${MISSING_FILES[*]}"
fi

# 7. Validate Terraform syntax
print_check "Validating Terraform configuration syntax..."
if terraform init -backend=false &> /dev/null && terraform validate &> /dev/null; then
    print_pass "Terraform configuration is valid"
else
    print_fail "Terraform configuration has errors"
    print_info "Run 'terraform validate' for details"
fi

# 8. Check for SSH key configuration
print_check "Checking SSH key configuration..."
if [ -f "terraform.tfvars" ]; then
    KEY_NAME=$(grep -E "^key_name" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "")
    if [ -n "$KEY_NAME" ]; then
        print_info "Configured key name: $KEY_NAME"
        
        # Check if key exists in AWS (requires AWS CLI and credentials)
        if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
            REGION=$(grep -E "^aws_region" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "us-east-1")
            if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
                print_pass "SSH key pair exists in AWS"
            else
                print_fail "SSH key pair '$KEY_NAME' not found in AWS region $REGION"
                print_info "Create with: aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem"
            fi
        fi
    else
        print_warn "key_name not specified in terraform.tfvars"
    fi
fi

# 9. Check security configuration
print_check "Checking security configuration..."
if [ -f "terraform.tfvars" ]; then
    # Check SSH CIDR configuration
    if grep -q "allowed_ssh_cidrs.*0.0.0.0/0" terraform.tfvars; then
        print_warn "SSH access is open to the world (0.0.0.0/0) - NOT RECOMMENDED for production"
        print_info "Restrict to your IP: allowed_ssh_cidrs = [\"YOUR_IP/32\"]"
    else
        print_pass "SSH access appears to be restricted"
    fi
    
    # Check encryption setting
    if grep -q "encrypt_root_volume.*true" terraform.tfvars; then
        print_pass "Root volume encryption is enabled"
    elif grep -q "encrypt_root_volume.*false" terraform.tfvars; then
        print_warn "Root volume encryption is disabled - NOT RECOMMENDED for production"
    fi
fi

# 10. Check instance type configuration
print_check "Checking instance type configuration..."
if [ -f "terraform.tfvars" ]; then
    INSTANCE_TYPE=$(grep -E "^instance_type" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "")
    if [ -n "$INSTANCE_TYPE" ]; then
        print_info "Configured instance type: $INSTANCE_TYPE"
        
        # Provide recommendations based on instance type
        case "$INSTANCE_TYPE" in
            t3.micro|t2.micro)
                print_info "Small instance - suitable for development/testing only"
                ;;
            t3.small|t2.small)
                print_info "Small instance - suitable for low-traffic applications"
                ;;
            t3.medium|t2.medium)
                print_pass "Medium instance - good for standard workloads"
                ;;
            m5.*|m6i.*)
                print_pass "General purpose instance - suitable for production"
                ;;
            c5.*|c6i.*)
                print_pass "Compute optimized instance - suitable for CPU-intensive workloads"
                ;;
            *)
                print_info "Instance type: $INSTANCE_TYPE"
                ;;
        esac
    fi
fi

# 11. Check storage configuration
print_check "Checking storage configuration..."
if [ -f "terraform.tfvars" ]; then
    VOLUME_TYPE=$(grep -E "^root_volume_type" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "")
    VOLUME_SIZE=$(grep -E "^root_volume_size" terraform.tfvars | cut -d'=' -f2 | tr -d ' ' || echo "")
    
    if [ -n "$VOLUME_TYPE" ]; then
        print_info "Volume type: $VOLUME_TYPE"
        if [ "$VOLUME_TYPE" == "gp3" ]; then
            print_pass "Using gp3 (recommended for best price/performance)"
        elif [ "$VOLUME_TYPE" == "gp2" ]; then
            print_info "Using gp2 (consider upgrading to gp3)"
        fi
    fi
    
    if [ -n "$VOLUME_SIZE" ]; then
        print_info "Volume size: ${VOLUME_SIZE}GB"
        if [ "$VOLUME_SIZE" -lt 10 ]; then
            print_fail "Volume size too small (minimum 10GB for RHEL 8)"
        elif [ "$VOLUME_SIZE" -ge 10 ] && [ "$VOLUME_SIZE" -lt 20 ]; then
            print_warn "Small volume size - may need expansion"
        else
            print_pass "Volume size is adequate"
        fi
    fi
fi

# 12. Check network configuration
print_check "Checking network configuration..."
if [ -f "terraform.tfvars" ]; then
    VPC_CIDR=$(grep -E "^vpc_cidr" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "")
    if [ -n "$VPC_CIDR" ]; then
        print_info "VPC CIDR: $VPC_CIDR"
        print_pass "Network configuration defined"
    fi
fi

# ============================================================================
# Summary
# ============================================================================

print_header "Validation Summary"

echo -e "${GREEN}Checks Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "${RED}Checks Failed: $CHECKS_FAILED${NC}"

echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment validation PASSED${NC}"
    echo -e "${GREEN}You can proceed with: terraform init && terraform plan${NC}"
    exit 0
else
    echo -e "${RED}✗ Deployment validation FAILED${NC}"
    echo -e "${RED}Please fix the issues above before deploying${NC}"
    exit 1
fi
