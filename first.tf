provider "aws" {
  region     = "ap-northeast-1"
  access_key = ""
  secret_key = ""
}

#create VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}

#create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod-gateway"
  }
}

#c create custome route table

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route"
  }
}

# create subnet

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "subnet-1"
  }

}

# Associate the subnet with the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt.id
}

# creating the security group

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 480
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#Network Interface
resource "aws_network_interface" "web-server_nic" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#assifning the elastic IP
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.gw
  ]
}

# create a ubuntu server

resource "aws_instance" "ec2-1" {
  ami               = "ami-088da9557aae42f39"
  instance_type     = "t2.micro"
  availability_zone = "ap-northeast-1a"
  key_name          = "ec2"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server_nic.id
  }

  user_data = <<-EOF
                  #!/bin/bash
                  sudo apt update -y
                  sudo apt install apache2 -y
                  sudo systemctl start apache2
                  EOF

  tags = {
    "Name" = "ec2-1"
  }
}


# resource "aws_vpc" "my_vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "production_vpc"
#   }
# }

# resource "aws_subnet" "subnet-1" {
#   vpc_id            = aws_vpc.my_vpc.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "ap-northeast-1a"

#   tags = {
#     Name = "subnet-1"
#   }
# }


# resource "aws_instance" "first-server" {
#   ami           = "ami-088da9557aae42f39"
#   instance_type = "t3.micro"
#   tags = {
#     Name = "HelloWorld-ec2"
#   }
# }


# resource "<provider>_<resource_type>" "name" {
# for diffrent resources types check out the providers docs on terrform.io
# name scope is only extented to the terraform it is unknown for the AWS or any cloud provider.
#     config options.....
#     key = "value"
#     key2 = "another value"
# }
