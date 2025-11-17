#!/bin/bash
# ============================================================================
# Red Hat Enterprise Linux 7 Bootstrap Script
# ============================================================================
# This script configures a fresh RHEL 7 instance for enterprise deployment
# Designed to work with the Terraform Enterprise module deployment
# ============================================================================

set -e  # Exit on any error

# Variables
LOG_FILE="/var/log/rhel7_bootstrap.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log_message "Starting RHEL 7 Enterprise Bootstrap Script"

# ============================================================================
# System Update and Package Management
# ============================================================================

log_message "Updating system packages..."
yum update -y

log_message "Installing essential packages..."
yum install -y \
    wget \
    curl \
    vim \
    htop \
    git \
    unzip \
    tar \
    rsync \
    screen \
    tmux \
    tree \
    net-tools \
    telnet \
    nmap-ncat \
    bind-utils \
    policycoreutils-python \
    setools-console

# ============================================================================
# Security Configuration
# ============================================================================

log_message "Configuring security settings..."

# Update SSH configuration for better security
if [ -f /etc/ssh/sshd_config ]; then
    log_message "Hardening SSH configuration..."
    
    # Backup original configuration
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply security settings
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # Add additional security settings
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
    
    # Restart SSH service
    systemctl restart sshd
    log_message "SSH configuration updated and service restarted"
fi

# Configure firewall
log_message "Configuring firewall..."
systemctl enable firewalld
systemctl start firewalld

# Allow SSH
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# ============================================================================
# CloudWatch Agent Installation (if monitoring is enabled)
# ============================================================================

log_message "Installing CloudWatch Agent..."
wget -O /tmp/amazon-cloudwatch-agent.rpm \
    https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm

if [ -f /tmp/amazon-cloudwatch-agent.rpm ]; then
    yum localinstall -y /tmp/amazon-cloudwatch-agent.rpm
    log_message "CloudWatch Agent installed successfully"
    
    # Create basic CloudWatch configuration
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOL'
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "read_bytes",
                    "write_bytes",
                    "reads",
                    "writes"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/rhel7/system",
                        "log_stream_name": "{instance_id}/messages",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/secure",
                        "log_group_name": "/aws/ec2/rhel7/security",
                        "log_stream_name": "{instance_id}/secure",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOL
    
    log_message "CloudWatch Agent configuration created"
else
    log_message "Failed to download CloudWatch Agent"
fi

# ============================================================================
# AWS CLI Installation
# ============================================================================

log_message "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
if [ -f /tmp/awscliv2.zip ]; then
    unzip -q /tmp/awscliv2.zip -d /tmp/
    /tmp/aws/install
    log_message "AWS CLI v2 installed successfully"
    /usr/local/bin/aws --version
else
    log_message "Failed to download AWS CLI v2"
fi

# ============================================================================
# System Optimization
# ============================================================================

log_message "Applying system optimizations..."

# Optimize kernel parameters
cat >> /etc/sysctl.conf << 'EOL'

# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Security optimizations
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOL

sysctl -p

# ============================================================================
# User Configuration
# ============================================================================

log_message "Configuring user environment..."

# Create .bashrc improvements for ec2-user
cat >> /home/ec2-user/.bashrc << 'EOL'

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Custom prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# History settings
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
export HISTFILESIZE=10000
shopt -s histappend

# AWS region
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOL

chown ec2-user:ec2-user /home/ec2-user/.bashrc

# ============================================================================
# Service Configuration
# ============================================================================

log_message "Configuring services..."

# Enable and start essential services
systemctl enable chronyd
systemctl start chronyd

# Configure logrotate
cat > /etc/logrotate.d/rhel7_bootstrap << 'EOL'
/var/log/rhel7_bootstrap.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOL

# ============================================================================
# Completion and Verification
# ============================================================================

log_message "Bootstrap script completed successfully!"

# Create completion marker
echo "RHEL 7 Enterprise Bootstrap completed at $TIMESTAMP" > /var/log/bootstrap_complete.log

# Display system information
log_message "System Information:"
log_message "Hostname: $(hostname)"
log_message "IP Address: $(hostname -I)"
log_message "OS Version: $(cat /etc/redhat-release)"
log_message "Kernel Version: $(uname -r)"
log_message "Uptime: $(uptime)"

# Display installed packages versions
log_message "Key Package Versions:"
log_message "AWS CLI: $(/usr/local/bin/aws --version 2>&1)"
log_message "Git: $(git --version)"
log_message "Curl: $(curl --version | head -n1)"

log_message "Bootstrap process completed. Instance is ready for use."

exit 0
