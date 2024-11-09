#!/bin/bash
# Stop Nginx service
sudo systemctl stop nginx

# Optionally, you can kill the running dotnet process if necessary
pkill -f 'dotnet dotnet-app.dll'
