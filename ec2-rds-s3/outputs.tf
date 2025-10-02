# ========================================
# VPC Outputs
# ========================================

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "db_subnet_ids" {
  value       = module.vpc.db_subnet_ids
  description = "Database subnet IDs"
}

# ========================================
# RDS Outputs
# ========================================

output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS database endpoint"
  sensitive   = true
}

output "rds_database_name" {
  value       = aws_db_instance.main.db_name
  description = "RDS database name"
}

# ========================================
# S3 Outputs
# ========================================

output "s3_bucket_name" {
  value       = aws_s3_bucket.images.id
  description = "S3 bucket name for images"
}

# ========================================
# EC2 Outputs
# ========================================

output "ec2_public_ip" {
  value       = aws_instance.web.public_ip
  description = "EC2 instance public IP address"
}

output "ec2_instance_id" {
  value       = aws_instance.web.id
  description = "EC2 instance ID"
}

# ========================================
# Connection Information
# ========================================

output "application_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "Application URL"
}

output "ssh_command" {
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.web.public_ip}"
  description = "SSH command (if you have a key pair)"
}

output "ssm_connect_command" {
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
  description = "AWS Systems Manager Session Manager command (recommended - no SSH key needed)"
}

# ========================================
# Summary
# ========================================

output "deployment_summary" {
  value = <<-EOT
    
    ============================================
    🎉 Infrastructure Deployed Successfully!
    ============================================
    
    📦 Resources Created:
    - VPC with public/private/db subnets across 2 AZs
    - NAT Gateway for private subnet internet access
    - RDS PostgreSQL database (${var.db_instance_class})
    - S3 bucket for image storage
    - EC2 web server (${var.ec2_instance_type})
    - Security groups for EC2, Lambda, and RDS
    
    🌐 Access Your Application:
    URL: http://${aws_instance.web.public_ip}
    
    🔐 Connect to EC2:
    SSM (recommended): aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}
    SSH (if key exists): ssh -i your-key.pem ec2-user@${aws_instance.web.public_ip}
    
    🗄️ Database:
    Endpoint: ${aws_db_instance.main.address}:${aws_db_instance.main.port}
    Database: ${aws_db_instance.main.db_name}
    Username: ${var.db_username}
    
    💾 S3 Bucket:
    Name: ${aws_s3_bucket.images.id}
    
    ⚠️  Next Steps:
    1. Wait 2-3 minutes for EC2 user data script to complete
    2. Visit http://${aws_instance.web.public_ip} to see the application
    3. Upload some images to test S3 integration
    4. Check CloudWatch Logs for any errors
    
    ============================================
    
  EOT
  description = "Deployment summary with all important information"
}
