# Image Gallery Infrastructure - EC2, RDS, S3, Lambda

This Terraform project deploys a complete AWS infrastructure for an image gallery application using:
- **VPC** with public/private/database subnets across 2 AZs
- **RDS PostgreSQL** for metadata storage
- **S3** for image storage
- **EC2** web server running Flask application
- **NAT Gateway** for private subnet internet access
- **Security Groups** for network isolation

---

## 🏗️ Architecture

```
Internet
   ↓
Internet Gateway
   ↓
┌────────────────────────────────────────────────────┐
│                  VPC 10.0.0.0/16                   │
│                                                    │
│  ┌──────────────┐       ┌──────────────┐          │
│  │ Public       │       │ Public       │          │
│  │ Subnet       │       │ Subnet       │          │
│  │ us-east-1a   │       │ us-east-1b   │          │
│  │              │       │              │          │
│  │ EC2 Web 🌐   │       │ NAT Gateway  │          │
│  └──────────────┘       └──────┬───────┘          │
│                                │                  │
│  ┌──────────────┐       ┌──────┴───────┐          │
│  │ Private      │       │ Private      │          │
│  │ Subnet       │       │ Subnet       │          │
│  │ us-east-1a   │       │ us-east-1b   │          │
│  │              │       │              │          │
│  │ (Lambda)     │       │ (Lambda)     │          │
│  └──────┬───────┘       └──────┬───────┘          │
│         │                      │                  │
│  ┌──────┴───────┐       ┌──────┴───────┐          │
│  │ DB Subnet    │       │ DB Subnet    │          │
│  │ us-east-1a   │       │ us-east-1b   │          │
│  │              │       │              │          │
│  │ RDS 🗄️       │       │ (Standby)    │          │
│  └──────────────┘       └──────────────┘          │
│                                                    │
│  VPC Endpoint → S3 💾 (private access)             │
└────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **(Optional)** SSH key pair for EC2 access

---

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
cd c:/git/terraform/ec2-rds-s3
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan -var="db_password=YourSecurePassword123!"
```

### 4. Deploy Infrastructure
```bash
terraform apply -var="db_password=YourSecurePassword123!"
```

⏱️ **Deployment time**: ~10-15 minutes (RDS takes the longest)

### 5. Get Outputs
```bash
terraform output deployment_summary
```

---

## 🔐 Security Configuration

### Database Password
**Never commit passwords to Git!** Set the password via:

```bash
# Option 1: Command line
terraform apply -var="db_password=YourSecurePassword123!"

# Option 2: Environment variable
export TF_VAR_db_password="YourSecurePassword123!"
terraform apply

# Option 3: terraform.tfvars (add to .gitignore!)
echo 'db_password = "YourSecurePassword123!"' > terraform.tfvars
terraform apply
```

### SSH Access
By default, SSH (port 22) is open to `0.0.0.0/0`. **Change this!**

Edit `security-groups.tf`:
```terraform
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP_ADDRESS/32"]  # ← Your IP only!
}
```

**Recommended**: Use AWS Systems Manager Session Manager (no SSH key needed):
```bash
aws ssm start-session --target i-xxxxxxxxx --region us-east-1
```

---

## 📦 Resources Created

| Resource | Type | Purpose |
|----------|------|---------|
| VPC | Network | 10.0.0.0/16 with 3 subnet tiers |
| Internet Gateway | Network | Public internet access |
| NAT Gateway | Network | Private subnet internet access |
| 2x Public Subnets | Network | EC2 web server |
| 2x Private Subnets | Network | Lambda functions (future) |
| 2x DB Subnets | Network | RDS database |
| S3 Gateway Endpoint | Network | Private S3 access (no NAT cost) |
| RDS PostgreSQL | Database | Image metadata storage |
| S3 Bucket | Storage | Image file storage |
| EC2 Instance | Compute | Flask web application |
| 3x Security Groups | Security | Network isolation |
| IAM Roles & Policies | Security | S3 and SSM access |

---

## 💰 Cost Estimate (us-east-1)

| Resource | Cost/Month | Notes |
|----------|------------|-------|
| EC2 t3.micro | ~$8 | Free tier: 750 hrs/month |
| RDS db.t4g.micro | ~$12 | Free tier: 750 hrs/month |
| NAT Gateway | ~$32 | + data transfer |
| EBS 20GB | ~$2 | |
| S3 Storage | ~$0.023/GB | First 50TB |
| Data Transfer | Variable | First 100GB free/month |
| **Total (dev)** | **~$54/month** | **~$0 with free tier!** |

---

## 🧪 Testing

### 1. Wait for EC2 User Data
```bash
# Check if application is ready
curl http://$(terraform output -raw ec2_public_ip)/health
```

### 2. Access Web Application
```bash
# Get the URL
terraform output application_url

# Open in browser
open http://$(terraform output -raw ec2_public_ip)
```

### 3. Upload an Image
1. Visit the application URL
2. Click "Choose File" and select an image
3. Click "Upload"
4. Image is stored in S3 and displayed

### 4. Check S3 Bucket
```bash
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/uploads/
```

### 5. Connect to Database
```bash
# From EC2 (using SSM)
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# Inside EC2
psql -h <rds-endpoint> -U dbadmin -d imagegallery
```

---

## 🔧 Customization

### Change Region
Edit `variables.tf` or use `-var`:
```bash
terraform apply -var="aws_region=eu-west-1" -var="db_password=..."
```

### Change Instance Sizes
```bash
terraform apply \
  -var="ec2_instance_type=t3.small" \
  -var="db_instance_class=db.t4g.small" \
  -var="db_password=..."
```

### Enable Multi-AZ RDS (Production)
Edit `rds.tf`:
```terraform
multi_az = true  # Instead of: var.environment == "prod" ? true : false
```

### Add 2nd NAT Gateway (High Availability)
Edit `vpc.tf`:
```terraform
nat_gateway_count = 2  # Instead of: 1
```
**Cost**: +$32/month

---

## 📁 Project Structure

```
ec2-rds-s3/
├── main.tf                 # Provider configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── vpc.tf                  # VPC module usage
├── security-groups.tf      # Security group rules
├── rds.tf                  # RDS database
├── s3.tf                   # S3 bucket
├── ec2.tf                  # EC2 web server
├── user_data.sh            # EC2 bootstrap script
├── modules/
│   └── vpc/
│       ├── main.tf         # VPC resources
│       ├── variables.tf    # VPC variables
│       └── outputs.tf      # VPC outputs
└── README.md               # This file
```

---

## 🐛 Troubleshooting

### Application Not Loading
```bash
# Check EC2 user data logs
aws ssm start-session --target $(terraform output -raw ec2_instance_id)
sudo tail -f /var/log/cloud-init-output.log
```

### Database Connection Issues
```bash
# Test from EC2
psql -h <rds-endpoint> -U dbadmin -d imagegallery

# Check security groups
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

### S3 Access Denied
```bash
# Check EC2 IAM role
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/
```

---

## 🧹 Cleanup

### Destroy All Resources
```bash
terraform destroy -var="db_password=YourPassword"
```

⏱️ **Destruction time**: ~10 minutes

### Cost-Saving Tips
- Stop EC2 when not in use: ~$0/month
- Delete RDS snapshots manually
- Empty S3 bucket before destroying
- NAT Gateway runs 24/7 (~$32/month)

---

## 🔄 Next Steps

1. **Add Lambda Function** for image processing
   - Resize images
   - Create thumbnails
   - Extract metadata
   
2. **Add CloudFront CDN** for image delivery

3. **Add Application Load Balancer** for multi-AZ EC2

4. **Implement CI/CD Pipeline** with GitHub Actions

5. **Add Monitoring** with CloudWatch Dashboards

6. **Enable VPC Flow Logs** for network monitoring

---

## 📚 Learn More

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

## 📝 License

This project is for educational purposes.

---

## 👤 Author

Created as a learning project for AWS infrastructure with Terraform.

**Happy Learning! 🚀**
