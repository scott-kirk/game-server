resource "aws_iam_policy" "server-scaling" {
  name = "AutoScalingGroupAccess"
  path = "/service-role/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeScheduledActions",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:PutScheduledUpdateGroupAction"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "VisualEditor1"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_policy" "mount-minecraft-volume" {
  name = "mount-minecraft-volume"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:DescribeVolumes"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "VisualEditor0"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_service_linked_role" "api-gateway" {
  aws_service_name = "ops.apigateway.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}

resource "aws_iam_role" "mount-minecraft-volume" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  description          = "Allows EC2 instances to mount volumes"
  managed_policy_arns  = ["${aws_iam_policy.mount-minecraft-volume.arn}"]
  max_session_duration = "3600"
  name                 = "mount-minecraft-volume"
  path                 = "/"
}

resource "aws_iam_role" "server-scaling" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = ["${aws_iam_policy.server-scaling.arn}"]
  max_session_duration = "3600"
  name                 = "server-scaling"
  path                 = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "mount-minecraft-volume" {
  policy_arn = "${aws_iam_policy.mount-minecraft-volume.arn}"
  role       = "${aws_iam_role.mount-minecraft-volume.name}"
}

resource "aws_iam_instance_profile" "mount-minecraft-volume" {
  name = "mount-minecraft-volume"
  role = aws_iam_role.mount-minecraft-volume.name
}

resource "aws_iam_role_policy_attachment" "server-scaling" {
  policy_arn = "${aws_iam_policy.server-scaling.arn}"
  role       = "${aws_iam_role.server-scaling.name}"
}
