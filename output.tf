
output "dynamodb_table_name" {
  value = aws_dynamodb_table.book_inventory_table.name
}

output "dynamodb_s3_bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}

output "dynamodb_policy_name" {
  value = aws_iam_policy.dynamodb_policy.name
}

output "dynamodb_role_name" {
  value = aws_iam_role.dynamodb_role.name
}


output "vpc_id" {
  value = var.vpc_id
}

output "public_subnet_id" {
  value = aws_instance.dynamodb_reader.subnet_id
}

output "public_subnet_ids" {
  value = data.aws_subnets.public.ids
}

output "ami_id" {
  value = aws_instance.dynamodb_reader.id
}


output "ami_name" {
  value = data.aws_ami.amazon_linux.name
}


output "public_ip" {
  value = aws_instance.dynamodb_reader.public_ip
}

output "public_dns" {
  value = aws_instance.dynamodb_reader.public_dns
}


