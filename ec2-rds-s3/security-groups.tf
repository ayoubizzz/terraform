# ========================================
# Security Groups
# ========================================

# EC2 Web Application Security Group
resource "aws_security_group" "ec2_web" {
  name        = "${var.project_name}-ec2-web-${var.environment}"
  description = "Security group for EC2 web application"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # ✅ NO SSH PORT NEEDED! We use AWS Systems Manager Session Manager
  # Access via: aws ssm start-session --target <instance-id>
  # This is more secure: no exposed ports, IAM-controlled, full audit logs

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-ec2-web-sg"
    Environment = var.environment
  }
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-${var.environment}"
  description = "Security group for Lambda functions"
  vpc_id      = module.vpc.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-lambda-sg"
    Environment = var.environment
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-${var.environment}"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  # Allow PostgreSQL from Lambda
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "Allow PostgreSQL from Lambda"
  }

  # Allow PostgreSQL from EC2
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_web.id]
    description     = "Allow PostgreSQL from EC2"
  }

  # No outbound rules needed for RDS (not initiating connections)

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

# Outputs
output "ec2_web_sg_id" {
  value = aws_security_group.ec2_web.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}
