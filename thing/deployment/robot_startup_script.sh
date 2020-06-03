#! /bin/bash

# Install Apache
apt-get update
apt-get install -y apache2

# CD to Apache html
cd /var/www/html
cat <<EOF > index.html
<html><body><h1>I am a robot named __</h1></body></html>
EOF

# Install node

# Checkout robot demo client from git

# Install node dependencies

# Create cert

# Create device with IoT Core

# ^ TODO or opt to use a Container based deployment






