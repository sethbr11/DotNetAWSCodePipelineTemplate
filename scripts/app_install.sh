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
