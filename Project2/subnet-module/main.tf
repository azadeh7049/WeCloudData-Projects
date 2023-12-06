resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.output_vpc.id
  tags = {
    Name = "Project 2 IGW"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.output_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#public subnet
resource "aws_subnet" "project2_public_us_east_1a" {
  vpc_id            = aws_vpc.output_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Project2 Public Subnet"
  }
}

#routing table
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.project2_public_us_east_1a.id
  route_table_id = aws_route_table.public_rtb.id
}


#private subnet
resource "aws_subnet" "project2_private_us_east_1b" {
  vpc_id            = aws_vpc.output_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Project2private Subnet"
  }
}

resource "aws_instance" "private-ectwo" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.project2_private_us_east_1b.id
  associate_public_ip_address = "true"


  key_name = "as-key2"

  tags = {
    Name = "Project2 Azadeh private Instance"
  }
}
