output "start_url" {
  description = "Start URL for server"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/start-server"
}

output "stop_url" {
  description = "Stop URL for server"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/stop-server"
}

output "stop_time_url" {
  description = "Stop time URL for server"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/get-stop-time"
}
