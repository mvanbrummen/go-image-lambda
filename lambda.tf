resource "aws_lambda_function" "test_lambda" {
  filename      = "function.zip"
  function_name = "go-image-lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main"
  memory_size   = 128

  source_code_hash = filebase64sha256("function.zip")

  runtime = "go1.x"

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "arn:aws:s3:::dasless-images"
    }
  ]
}
EOF
}