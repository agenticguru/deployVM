# ============================================================================
# RHEL 7 Enterprise Module - Integrated with Existing Infrastructure
# ============================================================================
# This file demonstrates how to use the Terraform Enterprise module
# alongside the existing deployVM infrastructure (VPC, subnets, security groups)
# ============================================================================

# ============================================================================
# Local Values for Configuration Management
# ============================================================================

locals {
  # Common tags applied to all resources
  common_tags = {
    Environment    = var.environment
    Project        = var.project_name
    ManagedBy      = "terraform"
    Repository     = "deployVM"
    DeploymentType = "integrated-enterprise"
    OS             = "RHEL-7"
    Terraform      = "true"
  }

  # Instance naming convention
  instance_name = "${var.project_name}-${var.environment}-rhel7-enterprise"
  
  # Use enterprise variables if provided, otherwise fall back to existing infrastructure
  subnet_id = var.enterprise_subnet_id != null ? var.enterprise_subnet_id : aws_subnet.public.id
  security_groups = var.enterprise_security_group_ids != null ? var.enterprise_security_group_ids : [aws_security_group.redhat_sg.id]
}

# ============================================================================
# Terraform Enterprise Module Deployment (Primary Instance)
# ============================================================================

module "rhel7_primary_instance" {
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Required parameters
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name

  # Instance configuration
  instance_name = local.instance_name

  # Network configuration - integrate with existing infrastructure
  subnet_id              = local.subnet_id
  security_group_ids     = local.security_groups
  availability_zone      = coalesce(var.enterprise_availability_zone, data.aws_availability_zones.available.names[0])
  associate_public_ip    = var.enterprise_associate_public_ip

  # Storage configuration
  root_volume_type    = var.enterprise_root_volume_type
  root_volume_size    = var.enterprise_root_volume_size
  encrypt_root_volume = var.enterprise_encrypt_root_volume

  # Advanced configuration
  user_data                = var.enterprise_user_data
  iam_instance_profile     = var.enterprise_iam_instance_profile
  monitoring               = var.enterprise_enable_monitoring
  ebs_optimized            = var.enterprise_ebs_optimized
  disable_api_termination  = var.enterprise_disable_api_termination

  # Resource tagging
  tags = merge(local.common_tags, {
    Name = local.instance_name
    Role = "primary"
  })
}

# ============================================================================
# Additional Enterprise Instances (Optional Multi-Instance Deployment)
# ============================================================================

# Secondary instance for high availability (optional)
module "rhel7_secondary_instance" {
  count = var.enable_secondary_instance ? 1 : 0
  
  source  = "localterraform.com/ag/instance/aws"
  version = "~> 1.0"

  # Required parameters
  instance_type = var.enterprise_instance_type
  key_name      = var.enterprise_key_name

  # Instance configuration
  instance_name = "${local.instance_name}-secondary"

  # Network configuration - use different AZ for HA
  subnet_id              = local.subnet_id
  security_group_ids     = local.security_groups
  availability_zone      = data.aws_availability_zones.available.names[1]
  associate_public_ip    = var.enterprise_associate_public_ip

  # Storage configuration
  root_volume_type    = var.enterprise_root_volume_type
  root_volume_size    = var.enterprise_root_volume_size
  encrypt_root_volume = var.enterprise_encrypt_root_volume

  # Advanced configuration
  user_data                = var.enterprise_user_data
  iam_instance_profile     = var.enterprise_iam_instance_profile
  monitoring               = var.enterprise_enable_monitoring
  ebs_optimized            = var.enterprise_ebs_optimized
  disable_api_termination  = var.enterprise_disable_api_termination

  # Resource tagging
  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-secondary"
    Role = "secondary"
  })
}

# ============================================================================
# Data Sources (Reuse from main.tf or define here)
# ============================================================================

# This assumes the main.tf infrastructure exists
# If deploying standalone, uncomment the resource definitions below

# data "aws_vpc" "main" {
#   id = aws_vpc.main.id
# }

# data "aws_subnet" "public" {
#   id = aws_subnet.public.id
# }

# data "aws_security_group" "redhat_sg" {
#   id = aws_security_group.redhat_sg.id
# }

# ============================================================================
# Load Balancer for Multi-Instance Setup (Optional)
# ============================================================================

# Application Load Balancer for distributing traffic
resource "aws_lb" "rhel7_alb" {
  count = var.enable_load_balancer ? 1 : 0
  
  name               = "${var.project_name}-rhel7-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[0].id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = var.environment == "production" ? true : false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rhel7-alb"
    Type = "LoadBalancer"
  })
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  count = var.enable_load_balancer ? 1 : 0
  
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RHEL 7 Application Load Balancer"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

# Target group for RHEL instances
resource "aws_lb_target_group" "rhel7_tg" {
  count = var.enable_load_balancer ? 1 : 0
  
  name     = "${var.project_name}-rhel7-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rhel7-tg"
  })
}

# Attach primary instance to target group
resource "aws_lb_target_group_attachment" "rhel7_primary" {
  count = var.enable_load_balancer ? 1 : 0
  
  target_group_arn = aws_lb_target_group.rhel7_tg[0].arn
  target_id        = module.rhel7_primary_instance.instance_id
  port             = 80
}

# Attach secondary instance to target group
resource "aws_lb_target_group_attachment" "rhel7_secondary" {
  count = var.enable_load_balancer && var.enable_secondary_instance ? 1 : 0
  
  target_group_arn = aws_lb_target_group.rhel7_tg[0].arn
  target_id        = module.rhel7_secondary_instance[0].instance_id
  port             = 80
}

# ALB listener
resource "aws_lb_listener" "rhel7_listener" {
  count = var.enable_load_balancer ? 1 : 0
  
  load_balancer_arn = aws_lb.rhel7_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rhel7_tg[0].arn
  }
}

# ============================================================================
# CloudWatch Alarms for Monitoring (Optional)
# ============================================================================

# CPU utilization alarm for primary instance
resource "aws_cloudwatch_metric_alarm" "rhel7_primary_cpu" {
  count = var.enable_monitoring_alarms ? 1 : 0
  
  alarm_name          = "${local.instance_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [] # Add SNS topic ARN here for notifications

  dimensions = {
    InstanceId = module.rhel7_primary_instance.instance_id
  }

  tags = local.common_tags
}

# Status check alarm for primary instance
resource "aws_cloudwatch_metric_alarm" "rhel7_primary_status" {
  count = var.enable_monitoring_alarms ? 1 : 0
  
  alarm_name          = "${local.instance_name}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors ec2 status check"
  alarm_actions       = [] # Add SNS topic ARN here for notifications

  dimensions = {
    InstanceId = module.rhel7_primary_instance.instance_id
  }

  tags = local.common_tags
}

# ============================================================================
# Additional Variables for Integrated Deployment
# ============================================================================

variable "enable_secondary_instance" {
  description = "Enable deployment of a secondary RHEL 7 instance for high availability"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Enable Application Load Balancer for distributing traffic across instances"
  type        = bool
  default     = false
}

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms for instance monitoring"
  type        = bool
  default     = false
}

# ============================================================================
# Additional Outputs for Integrated Deployment
# ============================================================================

output "rhel7_primary_instance" {
  description = "Primary RHEL 7 instance details"
  value = {
    instance_id = module.rhel7_primary_instance.instance_id
    public_ip   = module.rhel7_primary_instance.public_ip
    private_ip  = try(module.rhel7_primary_instance.private_ip, "N/A")
  }
}

output "rhel7_secondary_instance" {
  description = "Secondary RHEL 7 instance details (if enabled)"
  value = var.enable_secondary_instance ? {
    instance_id = module.rhel7_secondary_instance[0].instance_id
    public_ip   = module.rhel7_secondary_instance[0].public_ip
    private_ip  = try(module.rhel7_secondary_instance[0].private_ip, "N/A")
  } : null
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer (if enabled)"
  value       = var.enable_load_balancer ? aws_lb.rhel7_alb[0].dns_name : null
}

output "integrated_deployment_summary" {
  description = "Summary of the integrated RHEL 7 deployment"
  value = {
    primary_instance   = module.rhel7_primary_instance.instance_id
    secondary_enabled  = var.enable_secondary_instance
    load_balancer     = var.enable_load_balancer
    monitoring_alarms = var.enable_monitoring_alarms
    vpc_id            = aws_vpc.main.id
    subnet_id         = aws_subnet.public.id
    security_group_id = aws_security_group.redhat_sg.id
  }
}