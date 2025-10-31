#!/bin/bash
echo "Starting Apache web server..."
systemctl start httpd
systemctl enable httpd
