
output "dynamodb_table_name" {
  value = aws_dynamodb_table.book_inventory_table.name
}

output "ami" {
  value = aws_instance.dynamodb_reader.id
}

output "public_ip" {
  value = aws_instance.dynamodb_reader.public_ip
}

output "public_dns" {
  value = aws_instance.dynamodb_reader.public_dns
}

output "public_subnet_ids" {
  value = data.aws_subnets.public.ids
}