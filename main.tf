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
  name        = "tschui-dynamodb-read"
  description = "Policy to access DynamoDB table"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:BatchGetItem",
            "dynamodb:DescribeImport",
            "dynamodb:ConditionCheckItem",
            "dynamodb:DescribeContributorInsights",
            "dynamodb:Scan",
            "dynamodb:ListTagsOfResource",
            "dynamodb:Query",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:DescribeGlobalTableSettings",
            "dynamodb:PartiQLSelect",
            "dynamodb:DescribeTable",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeGlobalTable",
            "dynamodb:GetItem",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:DescribeExport",
            "dynamodb:GetResourcePolicy",
            "dynamodb:DescribeKinesisStreamingDestination",
            "dynamodb:DescribeBackup",
            "dynamodb:GetRecords",
            "dynamodb:DescribeTableReplicaAutoScaling"
          ],
          "Resource" : "arn:aws:dynamodb:ap-southeast-1:255945442255:table/tschui-bookinventory"
        },
        {
          "Sid" : "VisualEditor1",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:ListContributorInsights",
            "dynamodb:DescribeReservedCapacityOfferings",
            "dynamodb:ListGlobalTables",
            "dynamodb:ListTables",
            "dynamodb:DescribeReservedCapacity",
            "dynamodb:ListBackups",
            "dynamodb:GetAbacStatus",
            "dynamodb:ListImports",
            "dynamodb:DescribeLimits",
            "dynamodb:DescribeEndpoints",
            "dynamodb:ListExports",
            "dynamodb:ListStreams"
          ],
          "Resource" : "*"
        }
      ]
    }

  )
}

resource "aws_iam_role" "dynamodb_role" {
  name = "tschui-dynamodb-read-role"
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

data "aws_vpc" "vpc_id" {
  filter {
    name   = "tag:Name"
    values = ["shared-vpc"] #vpc-04cdd2b9251b86e69 (shared-vpc)
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_id.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-public-*"] #subnet-0088a8912029e13c6 (shared-vpc-public-ap-southeast-1a)
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  # Filter by name or other parameters (e.g., Amazon Linux 2023)
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"] #ami-0f935a2ecd3a7bd5c, al2023-ami-2023.6.20241121.0-kernel-6.1-x86_64
  }
}


/*-Create EC2 Instanace-*/

resource "aws_instance" "dynamodb_reader" {
  ami           = data.aws_ami.amazon_linux.id # Replace with the Amazon Linux 2023 AMI ID
  instance_type = "t2.micro"                   # Choose the appropriate instance type
  #key_name                    = "tschui-dynamodb-reade.pem"    # Replace with your EC2 key pair name
  subnet_id                   = data.aws_subnets.public.ids[0] #Public Subnet ID, e.g. subnet-xxxxxxxxxxx. 
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.dynamodb_reader_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.dynamodb_reader_profile.name

  tags = {
    Name = "tschui-dynamodb-reader"
  }
}

/*-Create EC2 Securiy Group-*/

resource "aws_security_group" "dynamodb_reader_sg" {
  name        = "tschui-dynamodb-reader-sg"
  description = "Allow SSH and HTTPS access"
  vpc_id = data.aws_vpc.vpc_id.id
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
