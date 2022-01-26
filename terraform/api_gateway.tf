resource "aws_apigatewayv2_api" "lambda" {
  name          = "lambda"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "management"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "start-server" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.start-server.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "start-server" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /start-server"
  target    = "integrations/${aws_apigatewayv2_integration.start-server.id}"
}

resource "aws_lambda_permission" "start-server" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start-server.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*/start-server"
}

resource "aws_apigatewayv2_integration" "stop-server" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.stop-server.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "stop-server" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /stop-server"
  target    = "integrations/${aws_apigatewayv2_integration.stop-server.id}"
}

resource "aws_lambda_permission" "stop-server" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop-server.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*/stop-server"
}

resource "aws_apigatewayv2_integration" "get-stop-time" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.get-stop-time.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get-stop-time" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /get-stop-time"
  target    = "integrations/${aws_apigatewayv2_integration.get-stop-time.id}"
}

resource "aws_lambda_permission" "get-stop-time" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-stop-time.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*/get-stop-time"
}

