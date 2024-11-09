#!/bin/bash
# Build the .NET app
cd /home/ec2-user/dotnet-app && dotnet build

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Run the .NET app
dotnet /home/ec2-user/dotnet-app/bin/Debug/net8.0/dotnet-app.dll