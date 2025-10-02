# ========================================
# EC2 Web Application Instance
# ========================================

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 IAM Role
resource "aws_iam_role" "ec2_web" {
  name = "${var.project_name}-ec2-web-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-ec2-web-role"
    Environment = var.environment
  }
}

# Attach SSM policy (for Session Manager - no SSH needed!)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy for S3 access
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.images.arn,
        "${aws_s3_bucket.images.arn}/*"
      ]
    }]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_web" {
  name = "${var.project_name}-ec2-web-profile-${var.environment}"
  role = aws_iam_role.ec2_web.name
}

# User data script
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = aws_db_instance.main.db_name
    db_username = var.db_username
    db_password = var.db_password
    s3_bucket   = aws_s3_bucket.images.id
    region      = var.aws_region
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  # Network
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_web.id]
  associate_public_ip_address = true

  # IAM
  iam_instance_profile = aws_iam_instance_profile.ec2_web.name

  # User data
  user_data = data.template_file.user_data.rendered

  # Storage
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
  }
}

# Outputs
output "ec2_public_ip" {
  value       = aws_instance.web.public_ip
  description = "EC2 instance public IP"
}

output "ec2_instance_id" {
  value       = aws_instance.web.id
  description = "EC2 instance ID"
}

output "ec2_ssh_command" {
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.web.public_ip}"
  description = "SSH command to connect to EC2"
}

output "ec2_ssm_command" {
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
  description = "AWS Systems Manager Session Manager command (no SSH key needed!)"
}
