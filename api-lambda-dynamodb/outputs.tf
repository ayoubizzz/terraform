# ========================================
# API Gateway Outputs
# ========================================

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/products"
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.products_api.id
}

output "api_gateway_stage" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.dev.stage_name
}

# ========================================
# Lambda Outputs
# ========================================

output "get_products_lambda_arn" {
  description = "ARN of the GetProducts Lambda function"
  value       = aws_lambda_function.get_products.arn
}

output "get_products_lambda_name" {
  description = "Name of the GetProducts Lambda function"
  value       = aws_lambda_function.get_products.function_name
}

output "save_product_lambda_arn" {
  description = "ARN of the SaveProduct Lambda function"
  value       = aws_lambda_function.save_product.arn
}

output "save_product_lambda_name" {
  description = "Name of the SaveProduct Lambda function"
  value       = aws_lambda_function.save_product.function_name
}

# ========================================
# DynamoDB Outputs
# ========================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB products table"
  value       = aws_dynamodb_table.products.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB products table"
  value       = aws_dynamodb_table.products.arn
}

# ========================================
# CloudWatch Logs Outputs
# ========================================

output "api_gateway_log_group" {
  description = "CloudWatch log group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

output "get_products_log_group" {
  description = "CloudWatch log group for GetProducts Lambda"
  value       = aws_cloudwatch_log_group.get_products_lambda_logs.name
}

output "save_product_log_group" {
  description = "CloudWatch log group for SaveProduct Lambda"
  value       = aws_cloudwatch_log_group.save_product_lambda_logs.name
}

# ========================================
# Usage Instructions
# ========================================

output "usage_instructions" {
  description = "Instructions for using the API"
  value = <<-EOT
    
    ============================================
    API Gateway URL: ${aws_api_gateway_stage.dev.invoke_url}/products
    ============================================
    
    Test GET /products:
    curl ${aws_api_gateway_stage.dev.invoke_url}/products
    
    Test POST /products:
    curl -X POST ${aws_api_gateway_stage.dev.invoke_url}/products \
      -H "Content-Type: application/json" \
      -d '{"name":"Test Product","price":99.99,"category":"Electronics","description":"A test product"}'
    
    Query parameters (GET):
    - limit: Limit number of results (e.g., ?limit=10)
    - category: Filter by category (e.g., ?category=Electronics)
    
    DynamoDB Table: ${aws_dynamodb_table.products.name}
    
    CloudWatch Logs:
    - API Gateway: ${aws_cloudwatch_log_group.api_gateway_logs.name}
    - GetProducts Lambda: ${aws_cloudwatch_log_group.get_products_lambda_logs.name}
    - SaveProduct Lambda: ${aws_cloudwatch_log_group.save_product_lambda_logs.name}
    
  EOT
}
