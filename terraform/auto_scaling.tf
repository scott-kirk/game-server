resource "aws_autoscaling_group" "minecraft" {
  availability_zones        = ["${aws_ebs_volume.minecraft.availability_zone}"]
  capacity_rebalance        = "false"
  default_cooldown          = "300"
  desired_capacity          = "0"
  force_delete              = "false"
  health_check_grace_period = "300"
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.minecraft-template.id
    version = "$Latest"
  }

  max_instance_lifetime     = "0"
  max_size                  = "1"
  metrics_granularity       = "1Minute"
  min_size                  = "0"
  name                      = "minecraft"
  protect_from_scale_in     = "false"
  service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn
  wait_for_capacity_timeout = "10m"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-arm64-gp2"]
  }
}

resource "aws_launch_template" "minecraft-template" {
  default_version         = "1"
  disable_api_termination = "false"
  ebs_optimized           = "false"

  iam_instance_profile {
    arn = aws_iam_instance_profile.mount-minecraft-volume.arn
  }

  image_id                             = data.aws_ami.amazon-linux-2.id
  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"

    spot_options {
      block_duration_minutes         = "0"
      instance_interruption_behavior = "terminate"
      max_price                      = "0.008"
      spot_instance_type             = "one-time"
    }
  }

  instance_type          = "t4g.small"
  name                   = "minecraft-template"
  user_data              = "${file("template-data")}"
  network_interfaces {
    subnet_id                   = aws_subnet.minecraft.id
    security_groups             = ["${aws_security_group.minecraft.id}"]
  }
}
