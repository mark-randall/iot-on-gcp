#! /bin/bash

# Install Apache
apt-get update
apt-get install -y apache2
cat <<EOF > /var/www/html/index.html
<html><body><h1>I am a robot named __</h1></body></html>
EOF

