variable "name" {
  description = "Name tag for resources"
  type        = string
  default     = "demo-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "AWS region (used for endpoints)"
  type        = string
  default     = "eu-north-1"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnets" {
  description = "List of private/subnet CIDRs for app/lambda"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnets" {
  description = "List of DB subnet CIDRs"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create (0 = no NAT, 1 = single NAT, >=1 per AZ)"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
