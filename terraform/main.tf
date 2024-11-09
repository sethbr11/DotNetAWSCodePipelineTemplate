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
  key_name        = var.key_name
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_security_group.id]
  tags            = { Name = "Web Server" }

  # User data to install .NET
  user_data = <<-EOF
              #!/bin/bash
              # Update the system and install required packages
              sudo yum update -y
              sudo yum install -y nginx libicu wget

              # Set HOME environment variable 
              export HOME=/home/ec2-user

              # Install .NET SDK
              mkdir -p /home/ec2-user/dotnet
              wget https://download.visualstudio.microsoft.com/download/pr/ca6cd525-677e-4d3a-b66c-11348a6f920a/ec395f498f89d0ca4d67d903892af82d/dotnet-sdk-8.0.403-linux-x64.tar.gz
              tar -xvf dotnet-sdk-8.0.403-linux-x64.tar.gz -C /home/ec2-user/dotnet
              rm dotnet-sdk-8.0.403-linux-x64.tar.gz
              export PATH=$PATH:/home/ec2-user/dotnet

              # Create a new .NET web app
              dotnet new webapp -n dotnet-app
              cd dotnet-app && dotnet build

              # Set up Nginx reverse proxy for .NET app
              echo "server {
                  listen 80;
                  server_name _;
                  location / {
                      proxy_pass http://localhost:5000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }" | sudo tee /etc/nginx/conf.d/default.conf > /dev/null

              # Start and enable Nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx

              # Run the .NET app
              dotnet bin/Debug/net8.0/dotnet-app.dll
              EOF
}

/***********
Code Commit and Code Pipeline Configuration
************/
