resource "aws_vpc" "minecraft" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "minecraft"
  }

  tags_all = {
    Name = "minecraft"
  }
}

resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.minecraft.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.minecraft.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.minecraft.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_subnet" "minecraft" {
  vpc_id                  = aws_vpc.minecraft.id
  map_public_ip_on_launch = "true"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = aws_ebs_volume.minecraft.availability_zone

  tags = {
    Name = "Public Subnet"
  }
}

