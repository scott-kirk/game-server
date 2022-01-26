data "archive_file" "get_stop_time" {
  type        = "zip"
  output_path = "${path.module}/get_stop_time.zip"
  source {
    content  = <<EOF
import json
import boto3
import datetime

def lambda_handler(event, context):
    shutdown_time = boto3.client('autoscaling').describe_scheduled_actions(
        AutoScalingGroupName="minecraft",
        ScheduledActionNames=["shutdown"],
    )["ScheduledUpdateGroupActions"][0]["StartTime"].isoformat()

    return {
        'statusCode': 200,
        'body': json.dumps(shutdown_time)
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "get-stop-time" {
  architectures                  = ["arm64"]
  function_name                  = "get-stop-time"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = "128"
  package_type                   = "Zip"
  reserved_concurrent_executions = "-1"
  role                           = "${aws_iam_role.server-scaling.arn}"
  runtime                        = "python3.9"
  filename                       = "${data.archive_file.get_stop_time.output_path}"
  source_code_hash               = "${data.archive_file.get_stop_time.output_base64sha256}"
  timeout                        = "3"

  tracing_config {
    mode = "PassThrough"
  }
}

data "archive_file" "start-server" {
  type        = "zip"
  output_path = "${path.module}/start-server.zip"
  source {
    content  = <<EOF
import json
import boto3
import datetime

def lambda_handler(event, context):
    autoscaling = boto3.client('autoscaling')
    shutdown_time = (datetime.datetime.now() + datetime.timedelta(hours=3)).astimezone()
    autoscaling.put_scheduled_update_group_action(
        AutoScalingGroupName="minecraft",
        ScheduledActionName="shutdown",
        StartTime=shutdown_time,
        DesiredCapacity=0,
    )
    autoscaling.update_auto_scaling_group(AutoScalingGroupName="minecraft", DesiredCapacity=1)
    return {
        'statusCode': 200,
        'body': json.dumps(shutdown_time.isoformat())
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "start-server" {
  architectures                  = ["arm64"]
  function_name                  = "start-server"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = "128"
  package_type                   = "Zip"
  reserved_concurrent_executions = "-1"
  role                           = "${aws_iam_role.server-scaling.arn}"
  runtime                        = "python3.9"
  filename                       = "${data.archive_file.start-server.output_path}"
  source_code_hash               = "${data.archive_file.start-server.output_base64sha256}"
  timeout                        = "10"

  tracing_config {
    mode = "PassThrough"
  }
}

data "archive_file" "stop-server" {
  type        = "zip"
  output_path = "${path.module}/stop-server.zip"
  source {
    content  = <<EOF
import json
import boto3
import datetime

def lambda_handler(event, context):
    shutdown_time = (datetime.datetime.now() + datetime.timedelta(minutes=3)).astimezone()
    boto3.client('autoscaling').put_scheduled_update_group_action(
        AutoScalingGroupName="minecraft",
        ScheduledActionName="shutdown",
        StartTime=shutdown_time,
        DesiredCapacity=0,
    )

    return {
        'statusCode': 200,
        'body': json.dumps(shutdown_time.isoformat())
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "stop-server" {
  architectures                  = ["arm64"]
  function_name                  = "stop-server"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = "128"
  package_type                   = "Zip"
  reserved_concurrent_executions = "-1"
  role                           = "${aws_iam_role.server-scaling.arn}"
  runtime                        = "python3.9"
  filename                       = "${data.archive_file.stop-server.output_path}"
  source_code_hash               = "${data.archive_file.stop-server.output_base64sha256}"
  timeout                        = "10"

  tracing_config {
    mode = "PassThrough"
  }
}
