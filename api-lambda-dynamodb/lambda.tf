# Archive Lambda functions for deployment
data "archive_file" "get_products_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/get_products"
  output_path = "${path.module}/lambda_functions/get_products.zip"
}

data "archive_file" "save_product_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/save_product"
  output_path = "${path.module}/lambda_functions/save_product.zip"
}

# ========================================
# GetProducts Lambda Function
# ========================================

resource "aws_lambda_function" "get_products" {
  filename         = data.archive_file.get_products_lambda.output_path
  function_name    = "${var.project_name}-get-products-${var.environment}"
  role            = aws_iam_role.get_products_lambda_role.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.get_products_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.products.name
      ENVIRONMENT    = var.environment
    }
  }

  # Enable X-Ray tracing (optional)
  # tracing_config {
  #   mode = "Active"
  # }

  tags = {
    Name        = "${var.project_name}-get-products-lambda"
    Environment = var.environment
  }
}

# CloudWatch Log Group for GetProducts Lambda
resource "aws_cloudwatch_log_group" "get_products_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.get_products.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-get-products-logs"
    Environment = var.environment
  }
}

# ========================================
# SaveProduct Lambda Function
# ========================================

resource "aws_lambda_function" "save_product" {
  filename         = data.archive_file.save_product_lambda.output_path
  function_name    = "${var.project_name}-save-product-${var.environment}"
  role            = aws_iam_role.save_product_lambda_role.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.save_product_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.products.name
      ENVIRONMENT    = var.environment
    }
  }

  # Enable X-Ray tracing (optional)
  # tracing_config {
  #   mode = "Active"
  # }

  tags = {
    Name        = "${var.project_name}-save-product-lambda"
    Environment = var.environment
  }
}

# CloudWatch Log Group for SaveProduct Lambda
resource "aws_cloudwatch_log_group" "save_product_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.save_product.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-save-product-logs"
    Environment = var.environment
  }
}
