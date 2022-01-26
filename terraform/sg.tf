resource "aws_security_group" "minecraft" {
  description = "minecraft"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "prometheus metrics"
    from_port   = "9225"
    protocol    = "tcp"
    self        = "false"
    to_port     = "9225"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "minecraft"
    from_port   = "25565"
    protocol    = "tcp"
    self        = "false"
    to_port     = "25565"
  }

  name = "minecraft"

  tags = {
    Name = "minecraft"
  }

  tags_all = {
    Name = "minecraft"
  }

  vpc_id = "${aws_vpc.minecraft.id}"
}
