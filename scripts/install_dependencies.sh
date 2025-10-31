#!/bin/bash
echo "Updating packages and installing Apache..."
yum update -y
yum install -y httpd
