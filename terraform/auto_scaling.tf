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
  user_data              = "I2Nsb3VkLWNvbmZpZwpwYWNrYWdlX3VwZGF0ZTogdHJ1ZQpwYWNrYWdlX3VwZ3JhZGU6IHRydWUKcnVuY21kOgotIHdoaWxlICEgZWMyLW1ldGFkYXRhIC0tYWxsOyBkbyA6OyBkb25lCi0gUkVHSU9OPSQoZWMyLW1ldGFkYXRhIC0tYXZhaWxhYmlsaXR5LXpvbmUgfCBhd2sgJ3twcmludCAkMn0nIHwgc2VkICdzLy4kLy8nKQotIElOU1RBTkNFX0lEPSQoZWMyLW1ldGFkYXRhIC0taW5zdGFuY2UtaWQgfCBhd2sgJ3twcmludCAkMn0nKQotIFZPTFVNRV9JRD0kKGF3cyBlYzIgZGVzY3JpYmUtdm9sdW1lcyAtLWZpbHRlcnMgTmFtZT10YWc6TmFtZSxWYWx1ZXM9bWluZWNyYWZ0IC0tcmVnaW9uPSRSRUdJT04gLS1xdWVyeSAiVm9sdW1lc1swXS5Wb2x1bWVJZCIgIHwgdHIgLWQgJyInKQotIGF3cyBlYzIgYXR0YWNoLXZvbHVtZSAtLXZvbHVtZS1pZCAkVk9MVU1FX0lEIC0tZGV2aWNlIC9kZXYveHZkZiAtLWluc3RhbmNlLWlkICRJTlNUQU5DRV9JRCAtLXJlZ2lvbiAkUkVHSU9OCi0gbWtkaXIgL2RhdGEKLSByZXRyeUNudD0xNTsgd2FpdFRpbWU9MzA7IHdoaWxlIHRydWU7IGRvIG1vdW50IC9kZXYveHZkZiAvZGF0YTsgaWYgWyAkPyA9IDAgXSB8fCBbICRyZXRyeUNudCAtbHQgMSBdOyB0aGVuIGVjaG8gRmlsZSBzeXN0ZW0gbW91bnRlZCBzdWNjZXNzZnVsbHk7IGJyZWFrOyBmaTsgZWNobyBGaWxlIHN5c3RlbSBub3QgYXZhaWxhYmxlLCByZXRyeWluZyB0byBtb3VudC47ICgocmV0cnlDbnQtLSkpOyBzbGVlcCAkd2FpdFRpbWU7IGRvbmU7Ci0gYW1hem9uLWxpbnV4LWV4dHJhcyBpbnN0YWxsIGRvY2tlciAmJiBzZXJ2aWNlIGRvY2tlciBzdGFydAotIGRvY2tlciBydW4gLWQgLXYgL2RhdGEvZGRjbGllbnQtY29uZmlnOi9jb25maWcgLS1uYW1lIGRkY2xpZW50IGxpbnV4c2VydmVyL2RkY2xpZW50Ci0gZG9ja2VyIHJ1biAtZCAtdiAvZGF0YS9taW5lY3JhZnQ6L2RhdGEgLXAgMjU1NjU6MjU1NjUgLXAgOTIyNTo5MjI1IC1lIEVVTEE9VFJVRSAtZSBFTkZPUkNFX1dISVRFTElTVD1UUlVFIC1lIFVTRV9BSUtBUl9GTEFHUz10cnVlIC1lIE1FTU9SWT0xMDAwTSAtbSAxNDQwTSAtZSBUWVBFPVBBUEVSIC0tcmVzdGFydCB1bmxlc3Mtc3RvcHBlZCAtLW5hbWUgbWluZWNyYWZ0IGl0emcvbWluZWNyYWZ0LXNlcnZlcg=="
  network_interfaces {
    subnet_id                   = aws_subnet.minecraft.id
    security_groups             = ["${aws_security_group.minecraft.id}"]
  }
}
