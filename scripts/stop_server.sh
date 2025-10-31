#!/bin/bash
echo "Stopping Apache web server..."
systemctl stop httpd || true
