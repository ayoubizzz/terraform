# DynamoDB Table for Products
resource "aws_dynamodb_table" "products" {
  name           = "${var.project_name}-products-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST" # On-demand pricing (no capacity planning needed)
  hash_key       = "productId"

  attribute {
    name = "productId"
    type = "S" # String
  }

  # Optional: Add Global Secondary Index for querying by category
  # attribute {
  #   name = "category"
  #   type = "S"
  # }
  # 
  # global_secondary_index {
  #   name            = "CategoryIndex"
  #   hash_key        = "category"
  #   projection_type = "ALL"
  # }

  # Enable point-in-time recovery (backups)
  point_in_time_recovery {
    enabled = true
  }

  # Enable encryption at rest
  server_side_encryption {
    enabled = true
  }

  # TTL configuration (optional - for auto-deletion of old products)
  # ttl {
  #   attribute_name = "expirationTime"
  #   enabled        = true
  # }

  tags = {
    Name        = "${var.project_name}-products-table"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
