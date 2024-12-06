terraform {
  backend "s3" {
    bucket = "tschui-s3-bucket"         # Replace with your S3 bucket name
    key    = "tschui-terraform.tfstate" # Path within the bucket to store the state file
    region = "ap-southeast-1"           # Specify the AWS region
  }
}