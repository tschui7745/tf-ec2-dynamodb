/*-Create Dynamodb Table-*/

resource "aws_dynamodb_table" "book_inventory_table" {
  name         = var.table_name        # Table name 
  hash_key     = var.hash_key_name     # Partition Key
  range_key    = var.range_key_name    # Sort Key
  billing_mode = var.billing_mode_name # On-demand billing
  attribute {
    name = var.hash_key_name
    type = "S" # String type
  }
  attribute {
    name = var.range_key_name
    type = "S" # String type
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name # The name of the S3 bucket (must be globally unique)
}

/*-Create IAM Policy--*/

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "tschui-dynamodb-read-${random_id.suffix.hex}"
  description = "Policy to access DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:ListTables",
          "dynamodb:ListStreams",
          "dynamodb:ListBackups",
          "dynamodb:ListGlobalTables",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeStream"
        ]
        Resource = "arn:aws:dynamodb:ap-southeast-1:123456789012:table/tschui-bookinventory"
      }
    ]
  })
}

/*-Create IAM Role--*/

resource "random_id" "suffix" {
  byte_length = 4
}


resource "aws_iam_role" "dynamodb_role" {
  name = "tschui-dynamodb-read-role-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com" # Replace with the service needing the role
        }
      }
    ]
  })
}

/*-Assign IAM Policy to IMA Role--*/

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = aws_iam_role.dynamodb_role.name
}

/*-Create EC2 Variable-*/

variable "vpc_id" {
  description = "vpc id"
  type        = string
  default     = "vpc-0e56f629cb53b94b7"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  # Filter by name or other parameters (e.g., Amazon Linux 2023)
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["public-*"]
  }
}

/*-Create EC2 Instanace-*/

resource "aws_instance" "dynamodb_reader" {
  #ami                         = data.aws_ami.amazon_linux.id        # Replace with the Amazon Linux 2023 AMI ID
  ami           = "ami-0f935a2ecd3a7bd5c" # Replace with the Amazon Linux 2023 AMI ID
  instance_type = "t2.micro"              # Choose the appropriate instance type
  #key_name                    = "tschui-dynamodb-reade.pem"    # Replace with your EC2 key pair name
  #subnet_id                   = data.aws_subnets.public.ids[0] #Public Subnet ID, e.g. subnet-xxxxxxxxxxx.
  subnet_id                   = "subnet-004425cdf7e7a28a8" #Public Subnet ID, e.g. subnet-xxxxxxxxxxx.
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.dynamodb_reader_sg.id]
  #security_group         = aws_security_group.dynamodb_reader_sg.id
  iam_instance_profile = aws_iam_instance_profile.dynamodb_reader_profile.name

  tags = {
    Name = "tschui-dynamodb-reader"
  }
}

/*-Create EC2 Securiy Group-*/

resource "aws_security_group" "dynamodb_reader_sg" {
  name        = "tschui-dynamodb-reader-sg"
  description = "Allow SSH and HTTPS access"
  vpc_id      = var.vpc_id #VPC ID (Same VPC as your EC2 subnet above), e.g. vpc-xxxxxxxxxxx
  lifecycle {
    create_before_destroy = true
  }

  // Allow SSH from home (replace with your public IP or use CIDR block)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow HTTPS (port 443) outbound to any endpoint
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow general outbound traffic (for the instance to access public URLs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*- Create IAM Profie with IAM Role-*/

resource "aws_iam_instance_profile" "dynamodb_reader_profile" {
  name = "tschui-dynamodb-reader-profile"
  role = aws_iam_role.dynamodb_role.name # Replace with the IAM role you created
}
