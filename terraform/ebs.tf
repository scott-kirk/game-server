variable "availability_zone" {
  type = string
}

resource "aws_ebs_volume" "minecraft" {
  availability_zone    = var.availability_zone
  encrypted            = "false"
  iops                 = "3000"
  multi_attach_enabled = "false"
  size                 = "6"

  tags = {
    Name = "minecraft"
  }

  tags_all = {
    Name = "minecraft"
  }

  throughput = "125"
  type       = "gp3"
}
