# Parameter Comparison: Before and After Revision

## Module: localterraform.com/ag/instance/aws

### BEFORE Revision (Extended Parameters)
The module was being called with 25+ parameters, many of which don't exist in RedHatProducts:

```hcl
module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # ❌ NOT in RedHatProducts
  ami_id                              = data.aws_ami.rhel7_enterprise.id
  associate_public_ip                 = var.enterprise_associate_public_ip
  kms_key_id                          = var.enterprise_kms_key_id
  ebs_block_device                    = var.enterprise_additional_volumes
  user_data                           = var.enterprise_user_data
  user_data_replace_on_change         = var.enterprise_user_data_replace_on_change
  iam_instance_profile                = var.enterprise_iam_instance_profile
  monitoring                          = var.enterprise_enable_monitoring
  ebs_optimized                       = var.enterprise_ebs_optimized
  disable_api_termination             = var.enterprise_disable_api_termination
  instance_initiated_shutdown_behavior = var.enterprise_shutdown_behavior
  source_dest_check                   = var.enterprise_source_dest_check
  metadata_options                    = { ... }
  volume_tags                         = { ... }

  # ✅ In RedHatProducts
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = var.enterprise_subnet_id
  security_group_ids     = var.enterprise_security_group_ids
  availability_zone      = var.enterprise_availability_zone
  instance_name          = var.enterprise_instance_name
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume
  tags                   = var.tags
}
```

### AFTER Revision (RedHatProducts Parameters Only)
The module now uses ONLY the 10 parameters that exist in RedHatProducts:

```hcl
module "rhel7_enterprise_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # ✅ All parameters from RedHatProducts repository
  instance_type          = var.enterprise_instance_type
  key_name               = var.enterprise_key_name
  subnet_id              = var.enterprise_subnet_id
  security_group_ids     = var.enterprise_security_group_ids
  availability_zone      = var.enterprise_availability_zone
  instance_name          = local.enterprise_instance_name
  root_volume_type       = var.enterprise_root_volume_type
  root_volume_size       = var.enterprise_root_volume_size
  encrypt_root_volume    = var.enterprise_encrypt_root_volume
  
  tags = merge(
    local.enterprise_tags,
    var.enterprise_additional_tags,
    {
      Name = local.enterprise_instance_name
    }
  )
}
```

## RedHatProducts Repository Parameters Reference

### From /sandbox/RedHatProducts/RedHatProducts/modules/redhat8/variables.tf

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "availability_zone" {
  description = "Availability zone for the instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "encrypt_root_volume" {
  description = "Whether to encrypt the root volume"
  type        = bool
}

variable "tags" {
  description = "Additional tags for the instance"
  type        = map(string)
}
```

## Summary of Changes

| Category | Before | After | Status |
|----------|--------|-------|--------|
| **Total Parameters** | 25+ | 10 | ✅ Reduced |
| **RedHatProducts Params** | 10 | 10 | ✅ Preserved |
| **Non-RedHatProducts Params** | 15+ | 0 | ✅ Removed |
| **Module Reference** | localterraform.com/ag/instance/aws | localterraform.com/ag/instance/aws | ✅ Maintained |

## Parameters Removed

1. `ami_id` - AMI selection should be handled internally by the module
2. `associate_public_ip` - Not in RedHatProducts parameters
3. `kms_key_id` - Not in RedHatProducts parameters
4. `ebs_block_device` - Not in RedHatProducts parameters
5. `user_data` - Not in RedHatProducts parameters
6. `user_data_replace_on_change` - Not in RedHatProducts parameters
7. `iam_instance_profile` - Not in RedHatProducts parameters
8. `monitoring` - Not in RedHatProducts parameters
9. `ebs_optimized` - Not in RedHatProducts parameters
10. `disable_api_termination` - Not in RedHatProducts parameters
11. `instance_initiated_shutdown_behavior` - Not in RedHatProducts parameters
12. `source_dest_check` - Not in RedHatProducts parameters
13. `metadata_options` - Not in RedHatProducts parameters
14. `volume_tags` - Not in RedHatProducts parameters
15. `private_ip` - Not in RedHatProducts parameters

## Verification

✅ All module calls use only RedHatProducts parameters
✅ All variables match RedHatProducts parameter definitions
✅ All outputs reference only available parameters
✅ Example configurations updated
✅ Documentation reflects accurate parameter usage