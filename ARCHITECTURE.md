# Architecture Overview - RedHat 7 Deployment

## Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud (us-east-1)                     │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                          │  │
│  │                 redhat-deployment-vpc                         │  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │            Public Subnet (10.0.1.0/24)                 │  │  │
│  │  │            us-east-1a                                   │  │  │
│  │  │                                                         │  │  │
│  │  │  ┌───────────────────────────────────────────────────┐ │  │  │
│  │  │  │           EC2 Instance                            │ │  │  │
│  │  │  │   redhat-deployment-dev-redhat7-enhanced          │ │  │  │
│  │  │  │                                                   │ │  │  │
│  │  │  │   OS: Red Hat Enterprise Linux 7                 │ │  │  │
│  │  │  │   Type: t3.micro (2 vCPU, 1GB RAM)               │ │  │  │
│  │  │  │   Storage: 20GB gp3 (encrypted)                  │ │  │  │
│  │  │  │   Public IP: Auto-assigned                       │ │  │  │
│  │  │  │   Private IP: 10.0.1.x                          │ │  │  │
│  │  │  │                                                   │ │  │  │
│  │  │  │   Security Group: redhat-deployment-redhat-sg    │ │  │  │
│  │  │  │   ├── SSH (22): Configurable CIDR               │ │  │  │
│  │  │  │   ├── HTTP (80): 0.0.0.0/0                      │ │  │  │
│  │  │  │   ├── HTTPS (443): 0.0.0.0/0                    │ │  │  │
│  │  │  │   └── Outbound: All traffic                     │ │  │  │
│  │  │  └───────────────────────────────────────────────────┘ │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │              Route Table                                │  │  │
│  │  │   0.0.0.0/0 → Internet Gateway                         │  │  │
│  │  │   10.0.0.0/16 → Local                                  │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                             │                                 │  │
│  │                             │                                 │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │              Internet Gateway                           │  │  │
│  │  │          redhat-deployment-igw                          │  │  │
│  │  └─────────────────────────▲───────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────▲───────────────────────────────────┘
                                  │
                                  │
                   ┌──────────────▼──────────────┐
                   │           Internet           │
                   │                             │
                   │   SSH Access via Public IP  │
                   │   HTTP/HTTPS Traffic        │
                   └─────────────────────────────┘
```

## Component Details

### VPC (Virtual Private Cloud)
- **CIDR**: 10.0.0.0/16 (65,536 IP addresses)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled
- **Name**: redhat-deployment-vpc

### Public Subnet
- **CIDR**: 10.0.1.0/24 (256 IP addresses)
- **Availability Zone**: us-east-1a (first available)
- **Auto-assign Public IP**: Enabled
- **Name**: redhat-deployment-public-subnet

### Internet Gateway
- **Purpose**: Internet connectivity for VPC
- **Attached to**: VPC
- **Name**: redhat-deployment-igw

### Route Table
- **Type**: Public route table
- **Routes**:
  - 0.0.0.0/0 → Internet Gateway (internet traffic)
  - 10.0.0.0/16 → Local (VPC traffic)
- **Association**: Public subnet

### Security Group
- **Name**: redhat-deployment-redhat-sg
- **VPC**: Attached to deployment VPC
- **Rules**:
  - **Inbound**:
    - SSH (22/tcp): Configurable CIDR (default: 0.0.0.0/0)
    - HTTP (80/tcp): 0.0.0.0/0
    - HTTPS (443/tcp): 0.0.0.0/0
  - **Outbound**:
    - All traffic (0.0.0.0/0)

### EC2 Instance
- **AMI**: Latest Red Hat Enterprise Linux 7 (auto-selected)
- **Instance Type**: t3.micro (configurable)
- **Key Pair**: my-redhat-key (configurable)
- **Storage**: 20GB gp3 encrypted EBS volume
- **Networking**: Public subnet with auto-assigned public IP
- **Tags**: Name, Environment, Project, OS, Module

## Module Integration

### RedHat Products Module
```
Source: ../RedHatProducts/RedHatProducts/modules/redhat7
│
├── AMI Selection (data.aws_ami.redhat7)
│   └── Owner: 309956199498 (Red Hat)
│   └── Filter: RHEL-7.*-x86_64-*
│
├── Instance Resource (aws_instance.redhat7)
│   ├── AMI: Auto-selected latest RHEL 7
│   ├── Type: From variable
│   └── Key: From variable
│
└── Outputs
    ├── instance_id
    └── public_ip
```

### Enhanced Deployment Features
```
Enhanced Instance (aws_instance.redhat7_enhanced)
│
├── Network Integration
│   ├── VPC Subnet
│   ├── Security Groups
│   └── Public IP Assignment
│
├── Storage Configuration
│   ├── Volume Type (gp3)
│   ├── Volume Size (20GB)
│   ├── Encryption (enabled)
│   └── Delete on Termination
│
├── Initialization
│   ├── User Data Script
│   ├── System Updates
│   ├── Package Installation
│   └── Welcome Message
│
└── Tagging Strategy
    ├── Name
    ├── Environment
    ├── Project
    ├── OS
    └── Module
```

## Data Flow

### Deployment Process
1. **Terraform Init**: Download providers, initialize modules
2. **Plan Generation**: Calculate resource changes
3. **Resource Creation**:
   - VPC and networking components
   - Security group with rules
   - EC2 instance with enhancements
4. **Outputs**: Display connection information

### Network Traffic Flow
```
Internet → Internet Gateway → Route Table → Public Subnet → EC2 Instance
                                   ↑
                            Security Group
                         (Firewall Rules)
```

### SSH Connection Flow
```
User's Machine → Public IP → Security Group → EC2 Instance (port 22)
                                   ↑
                           Key-based Authentication
```

## Security Architecture

### Defense in Depth
1. **Network Level**: VPC isolation, subnet segmentation
2. **Transport Level**: Security group firewall rules
3. **Instance Level**: Key-based SSH authentication
4. **Storage Level**: EBS volume encryption
5. **OS Level**: Regular security updates via user data

### Access Control
- **SSH Access**: Configurable CIDR restrictions
- **HTTP/HTTPS**: Open for web services
- **Outbound**: Full internet access for updates
- **Key Management**: AWS-managed key pairs

## Scalability Considerations

### Current Architecture
- Single instance in single AZ
- Public subnet deployment
- Manual scaling via instance type changes

### Future Enhancements
- Multi-AZ deployment for high availability
- Auto Scaling Groups for dynamic scaling
- Load Balancer for traffic distribution
- Private subnets for enhanced security
- NAT Gateway for private instance internet access

## Cost Components

### Monthly Costs (US East)
```
EC2 Instance (t3.micro)     : $8.50
EBS Storage (20GB gp3)      : $1.60
Data Transfer (estimated)   : $1.00
NAT Gateway (if added)      : $32.00
Load Balancer (if added)    : $16.00
──────────────────────────────────
Base Configuration Total   : ~$11.00
```

## Monitoring Points

### Key Metrics to Monitor
- **EC2**: CPU utilization, memory usage, disk I/O
- **Network**: Data transfer, packet loss
- **Storage**: IOPS utilization, throughput
- **Security**: Failed SSH attempts, unusual traffic

### Recommended Alarms
- High CPU utilization (>80%)
- Low disk space (<20%)
- Network connectivity issues
- Security group rule violations

## Backup Strategy

### Current Implementation
- **EBS Snapshots**: Manual or scheduled
- **AMI Creation**: For complete instance backup
- **Configuration**: Terraform state for infrastructure

### Recommended Approach
- Daily EBS snapshots with retention policy
- Weekly AMI creation
- Infrastructure as Code version control
- Disaster recovery documentation

## Compliance and Governance

### Tagging Strategy
All resources tagged with:
- **Name**: Descriptive resource name
- **Environment**: dev/staging/prod
- **Project**: Project identifier
- **Owner**: Resource owner
- **CostCenter**: For cost allocation

### Security Compliance
- Encryption at rest (EBS volumes)
- Network isolation (VPC)
- Access logging capability
- Key-based authentication
- Regular security updates

This architecture provides a solid foundation for RedHat 7 deployments with room for enhancement based on specific requirements.