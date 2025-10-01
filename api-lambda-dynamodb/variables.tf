# ========================================
# Project Configuration Variables
# ========================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "products-api"
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
# Optional: DynamoDB Configuration
# ========================================

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# ========================================
# Optional: Lambda Configuration
# ========================================

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

# ========================================
# Optional: API Gateway Configuration
# ========================================

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 100
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 50
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway and Lambda"
  type        = bool
  default     = false
}

# ========================================
# Optional: Logging Configuration
# ========================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "api_gateway_log_level" {
  description = "API Gateway log level (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
