variable "region_name" {
  description = "region name of Dynamodb"
  type        = string
  default     = "ap-southeast-1"
}


variable "table_name" {
  description = "table name of Dynamodb"
  type        = string
  default     = "tschui-bookinventory"
}

variable "hash_key_name" {
  description = "hash key name of Dynamodb"
  type        = string
  default     = "ISBN"
}

variable "range_key_name" {
  description = "range key name of Dynamodb"
  type        = string
  default     = "Genre"
}

variable "billing_mode_name" {
  description = "billing mode name of Dynamodb"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "s3_bucket_name" {
  description = "s3 bucket name of Dynamodb"
  type        = string
  default     = "tschui-s3-bucket"
}