/***********
Provider Configuration
************/

terraform { 
  required_providers { 
    aws = { 
      source  = "hashicorp/aws" 
      version = "~> 5.0" 
    } 
  } 
} 

provider "aws" { 
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
} 

/***********
VPC Configuration
Create/Configure the VPC and Subnet
************/

# VPC
resource "aws_vpc" "account_vpc" {
  cidr_block = "10.0.0.0/16"
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.account_vpc.id
}

# PUBLIC SUBNET
resource "aws_subnet" "public_subnet" {
  vpc_id                    = aws_vpc.account_vpc.id
  cidr_block                = "10.0.0.0/24"
  availability_zone         = "us-east-2a"
  map_public_ip_on_launch   = true
  tags                      = { Name = "public_subnet" }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.account_vpc.id
}

# INTERNET ROUTE
resource "aws_route" "internet_route" {
  route_table_id          = aws_route_table.public_route_table.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.internet_gateway.id
}

# ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id         = aws_subnet.public_subnet.id
  route_table_id    = aws_route_table.public_route_table.id
}

/***********
Security Group Configuration
************/

# WEB SECURITY GROUP
resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Web security group that allows HTTP, HTTPS, and SSH traffic"
  vpc_id      = aws_vpc.account_vpc.id

  # Allow inbound web traffic with HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound web traffic with HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound SSH traffic (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/***********
EC2 Instance Configuration
************/

# EC2 INSTANCE FOR WEB SERVER
resource "aws_instance" "web_server" {
  ami             = "ami-0fae88c1e6794aa17" # Amazon Linux 2023 AMI
  instance_type   = "t2.micro"
  key_name        = "pdcserverkey"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_security_group.id]
  tags            = { Name = "Web Server" }
}

/***********
Code Commit and Code Pipeline Configuration
************/
