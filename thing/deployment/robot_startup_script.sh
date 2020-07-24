#! /bin/bash

# Install logging monitor. The monitor will automatically pick up logs sent to syslog.
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &

# Install Apache and git
apt-get update
apt-get install -y apache2
apt-get install -y git

# CD to Apache html
cd /var/www/html
cat <<EOF > index.html
<html><body><h1>Test IoT device</h1></body></html>
EOF

# Install nodejs
mkdir /opt/nodejs
curl https://nodejs.org/dist/v12.18.0/node-v12.18.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm

# Checkout robot demo client from git
git clone https://github.com/mark-randall/IoT_on_GCP.git
cd IoT_on_GCP/thing/app

# Install node dependencies
npm install

# Fetch device name from Compute Engine meta data
export TEST_DEVICE_NAME=$(curl "http://metadata/computeMetadata/v1/instance/attributes/test-device-name" -H "Metadata-Flavor: Google")

# Create cert
# Create device with IoT Core
sudo npm run create

# Start API and Test device
npm run start






