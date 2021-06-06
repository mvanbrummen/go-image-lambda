provider "aws" {
  region = "ap-southeast-2"
}

# Variables
variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "bucket" {
  type    = string
  default = "dasless-images"
}

variable "stage_name" {
  description = "The stage name(production/staging/etc..)"
  default     = "dev"
}

# API Gateway + Lambda
module "lambda_api" {
    source         = "git@github.com:mvanbrummen/tf-lambda-proxy-apigw.git"

  # General options
  project    = "go-image-lambda"
  stage_name = var.stage_name
  region     = var.region

  # Lambda options
  lambda_name    = "go-image-lambda"
  lambda_runtime = "go1.x"
  lambda_memory  = 128 
  lambda_timeout = 10
  lambda_package = "function.zip"
  lambda_handler = "main"
  
  lambda_env = {
    SOURCE_BUCKET = "dasless-images"
    SOURCE_ROOT_PATH = "assets/"
  }
}

# Extent Lambda role
resource "aws_iam_role_policy" "permissions" {
  name = "${module.lambda_api.lambda_role}-bucket-permission"
  role = module.lambda_api.lambda_role_id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "arn:aws:s3:::${var.bucket}*"
    }
  ]
}
EOF
}

# Outputs
output "endpoint" {
  description = "endpoint url"
  value       = module.lambda_api.api_url
}