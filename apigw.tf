resource "aws_api_gateway_rest_api" "rest_api" {
  name = "go-image-lambda-apigw"

  binary_media_types = ["*/*"]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id 
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.test_lambda.arn}/invocations"
}

resource "aws_api_gateway_deployment" "apig_deployment" {
  depends_on = [
    aws_api_gateway_resource.proxy,
    aws_api_gateway_method.method,
    aws_api_gateway_integration.integration
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.api_stage_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "apig_to_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name 
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:ap-southeast-2:492141138759:${aws_api_gateway_rest_api.rest_api.id}/*/*/*"
}