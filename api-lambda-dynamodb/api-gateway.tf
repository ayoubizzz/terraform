# ========================================
# IAM Role for API Gateway CloudWatch Logging
# ========================================

# This role allows API Gateway to write logs to CloudWatch
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.project_name}-api-gateway-cloudwatch-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-api-gateway-cloudwatch-role"
    Environment = var.environment
  }
}

# Attach the AWS managed policy for API Gateway to push logs to CloudWatch
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Set the CloudWatch Logs role ARN at the account level
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.api_gateway_cloudwatch_policy
  ]
}

# ========================================
# API Gateway REST API
# ========================================

resource "aws_api_gateway_rest_api" "products_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "REST API for managing products"

  endpoint_configuration {
    types = ["REGIONAL"] # REGIONAL for single region, EDGE for global with CloudFront
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# ========================================
# API Gateway Resources (URL Paths)
# ========================================

# /products resource
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id
  parent_id   = aws_api_gateway_rest_api.products_api.root_resource_id
  path_part   = "products"
}

# ========================================
# GET /products Method
# ========================================

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.products_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE" # Public endpoint (no authentication)

  request_parameters = {
    "method.request.querystring.limit"    = false # Optional query param
    "method.request.querystring.category" = false # Optional query param
  }
}

# Lambda integration for GET /products
resource "aws_api_gateway_integration" "get_products_integration" {
  rest_api_id             = aws_api_gateway_rest_api.products_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "POST"       # Always POST for Lambda
  type                    = "AWS_PROXY"  # Lambda proxy integration (passes full request to Lambda)
  uri                     = aws_lambda_function.get_products.invoke_arn
}

# ========================================
# POST /products Method
# ========================================

resource "aws_api_gateway_method" "post_product" {
  rest_api_id   = aws_api_gateway_rest_api.products_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "POST"
  authorization = "NONE" # Public endpoint

  request_validator_id = aws_api_gateway_request_validator.body_validator.id

  request_models = {
    "application/json" = aws_api_gateway_model.product_model.name
  }
}

# Request validator (validates body before invoking Lambda)
resource "aws_api_gateway_request_validator" "body_validator" {
  name                        = "body-validator"
  rest_api_id                 = aws_api_gateway_rest_api.products_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# Product model (JSON schema for validation)
resource "aws_api_gateway_model" "product_model" {
  rest_api_id  = aws_api_gateway_rest_api.products_api.id
  name         = "ProductModel"
  content_type = "application/json"

  schema = jsonencode({
    type     = "object"
    required = ["name", "price"]
    properties = {
      name = {
        type      = "string"
        minLength = 1
        maxLength = 255
      }
      description = {
        type      = "string"
        maxLength = 1000
      }
      price = {
        type    = "number"
        minimum = 0
      }
      category = {
        type      = "string"
        maxLength = 100
      }
    }
  })
}

# Lambda integration for POST /products
resource "aws_api_gateway_integration" "post_product_integration" {
  rest_api_id             = aws_api_gateway_rest_api.products_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.post_product.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.save_product.invoke_arn
}

# ========================================
# Lambda Permissions (Allow API Gateway to invoke Lambda)
# ========================================

resource "aws_lambda_permission" "api_gateway_get_products" {
  statement_id  = "AllowAPIGatewayInvokeGetProducts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_products.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict to this API only
  source_arn = "${aws_api_gateway_rest_api.products_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_save_product" {
  statement_id  = "AllowAPIGatewayInvokeSaveProduct"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_product.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict to this API only
  source_arn = "${aws_api_gateway_rest_api.products_api.execution_arn}/*/*"
}

# ========================================
# CORS Configuration (Optional - Uncomment if needed)
# ========================================

# OPTIONS method for CORS preflight
resource "aws_api_gateway_method" "options_products" {
  rest_api_id   = aws_api_gateway_rest_api.products_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
# 
resource "aws_api_gateway_integration" "options_products" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options_products.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
# 
resource "aws_api_gateway_method_response" "options_products_200" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options_products.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
# 
resource "aws_api_gateway_integration_response" "options_products" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options_products.http_method
  status_code = aws_api_gateway_method_response.options_products_200.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ========================================
# API Deployment & Stage
# ========================================

resource "aws_api_gateway_deployment" "products_api" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id

  depends_on = [
    aws_api_gateway_integration.get_products_integration,
    aws_api_gateway_integration.post_product_integration,
  ]

  lifecycle {
    create_before_destroy = true
  }

  # Trigger redeployment when code changes
  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_resource.products.id,
      aws_api_gateway_method.get_products.id,
      aws_api_gateway_method.post_product.id,
      aws_api_gateway_integration.get_products_integration.id,
      aws_api_gateway_integration.post_product_integration.id,
    ]))
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.products_api.id
  rest_api_id   = aws_api_gateway_rest_api.products_api.id
  stage_name    = var.environment

  xray_tracing_enabled = false # Enable X-Ray for distributed tracing (set to true if needed)

  # CloudWatch access logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }

  depends_on = [
    aws_api_gateway_account.main
  ]

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
  }
}

# ========================================
# CloudWatch Logs for API Gateway
# ========================================

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${var.project_name}-api-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-api-logs"
    Environment = var.environment
  }
}

# Method settings (logging, metrics, throttling)
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.products_api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*" # Apply to all methods

  settings {
    logging_level      = "INFO"  # ERROR, INFO, or OFF
    data_trace_enabled = true    # Log full request/response bodies
    metrics_enabled    = true    # Enable CloudWatch metrics

    # Throttling (optional)
    throttling_burst_limit = 100 # Max concurrent requests
    throttling_rate_limit  = 50  # Requests per second
  }
}

# ========================================
# Optional: Usage Plan & API Key
# ========================================

# Uncomment to add rate limiting and API key authentication
# 
# resource "aws_api_gateway_usage_plan" "basic" {
#   name = "${var.project_name}-basic-plan"
# 
#   api_stages {
#     api_id = aws_api_gateway_rest_api.products_api.id
#     stage  = aws_api_gateway_stage.dev.stage_name
#   }
# 
#   quota_settings {
#     limit  = 10000  # Max requests per period
#     period = "DAY"  # DAY, WEEK, or MONTH
#   }
# 
#   throttle_settings {
#     burst_limit = 100 # Max concurrent requests
#     rate_limit  = 50  # Requests per second
#   }
# }
# 
# resource "aws_api_gateway_api_key" "basic" {
#   name = "${var.project_name}-api-key"
# }
# 
# resource "aws_api_gateway_usage_plan_key" "basic" {
#   key_id        = aws_api_gateway_api_key.basic.id
#   key_type      = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.basic.id
# }
