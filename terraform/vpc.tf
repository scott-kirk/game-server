resource "aws_vpc" "minecraft" {
  cidr_block                = "10.0.0.0/16"

  tags = {
    Name = "minecraft"
  }

  tags_all = {
    Name = "minecraft"
  }
}

resource "aws_subnet" "minecraft" {
  vpc_id     = aws_vpc.minecraft.id
  cidr_block = "10.0.0.0/24"
  availability_zone = aws_ebs_volume.minecraft.availability_zone

  tags = {
    Name = "Public Subnet"
  }
}

