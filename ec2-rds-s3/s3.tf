# ========================================
# S3 Bucket for Image Storage
# ========================================

# S3 Bucket
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-images"
    Environment = var.environment
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Block public access
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule (optional: delete old files after 90 days)
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "delete-old-images"
    status = var.environment == "dev" ? "Enabled" : "Disabled"

    expiration {
      days = 90
    }
  }
}

# S3 bucket notification to Lambda (will be created later with Lambda)
# resource "aws_s3_bucket_notification" "images" {
#   bucket = aws_s3_bucket.images.id
#
#   lambda_function {
#     lambda_function_arn = aws_lambda_function.image_processor.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "uploads/"
#   }
#
#   depends_on = [aws_lambda_permission.allow_s3]
# }

# Outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.images.id
  description = "S3 bucket name for images"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.images.arn
  description = "S3 bucket ARN"
}
