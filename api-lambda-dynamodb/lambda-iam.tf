# ========================================
# IAM Role for GetProducts Lambda (Read-Only)
# ========================================

resource "aws_iam_role" "get_products_lambda_role" {
  name = "${var.project_name}-get-products-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-get-products-lambda-role"
    Environment = var.environment
  }
}

# CloudWatch Logs Policy for GetProducts Lambda
resource "aws_iam_role_policy" "get_products_cloudwatch_policy" {
  name = "cloudwatch-logs-policy"
  role = aws_iam_role.get_products_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB Read-Only Policy for GetProducts Lambda
resource "aws_iam_role_policy" "get_products_dynamodb_policy" {
  name = "dynamodb-read-policy"
  role = aws_iam_role.get_products_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*"
        ]
      }
    ]
  })
}

# ========================================
# IAM Role for SaveProduct Lambda (Write)
# ========================================

resource "aws_iam_role" "save_product_lambda_role" {
  name = "${var.project_name}-save-product-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-save-product-lambda-role"
    Environment = var.environment
  }
}

# CloudWatch Logs Policy for SaveProduct Lambda
resource "aws_iam_role_policy" "save_product_cloudwatch_policy" {
  name = "cloudwatch-logs-policy"
  role = aws_iam_role.save_product_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB Read/Write Policy for SaveProduct Lambda
resource "aws_iam_role_policy" "save_product_dynamodb_policy" {
  name = "dynamodb-write-policy"
  role = aws_iam_role.save_product_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.products.arn
      }
    ]
  })
}

# ========================================
# Optional: X-Ray Tracing Policy (for both Lambdas)
# ========================================

# resource "aws_iam_role_policy" "get_products_xray_policy" {
#   name = "xray-policy"
#   role = aws_iam_role.get_products_lambda_role.id
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "xray:PutTraceSegments",
#           "xray:PutTelemetryRecords"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }
# 
# resource "aws_iam_role_policy" "save_product_xray_policy" {
#   name = "xray-policy"
#   role = aws_iam_role.save_product_lambda_role.id
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "xray:PutTraceSegments",
#           "xray:PutTelemetryRecords"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }
