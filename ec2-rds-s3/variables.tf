# ========================================
# Project Configuration Variables
# ========================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "image-gallery"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-north-1"
}

# ========================================
# Database Configuration
# ========================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"  # Free tier eligible
}

variable "db_allocated_storage" {
  description = "Initial storage size in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage size for autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "imagegallery"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  # Set this via: terraform apply -var="db_password=YourSecurePassword123!"
  # Or use AWS Secrets Manager in production
}

variable "db_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# ========================================
# EC2 Configuration
# ========================================

variable "ec2_instance_type" {
  description = "EC2 instance type for web server"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
