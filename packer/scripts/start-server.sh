#!/bin/bash
SHAREDDIR=/ops/
CONFIGDIR=$SHAREDDIR/files
SCRIPTDIR=$SHAREDDIR/scripts

set -e

NOMADCONFIGDIR=/etc/nomad.d
CONSULCONFIGDIR=/etc/consul.d
HOME_DIR=ubuntu

# Wait for network
sleep 15

SERVER_COUNT=$1
RETRY_JOIN=$2
IP_ADDRESS=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+')
DOCKER_BRIDGE_IP_ADDRESS=$(ip -4 address show docker0 | awk '/inet / { print $2 }' | cut -d/ -f1)

# Consul
## Replace existing Consul binary if remote file exists
if [[ `wget -S --spider $CONSUL_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $CONSUL_BINARY > consul.zip
  sudo unzip -o consul.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/consul
  sudo chown root:root /usr/local/bin/consul
fi

sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/consul-server.hcl
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/consul-server.hcl
sed -i "s/RETRY_JOIN/$RETRY_JOIN/g" $CONFIGDIR/consul-server.hcl
sudo cp $CONFIGDIR/consul-server.hcl $CONSULCONFIGDIR
sudo cp $CONFIGDIR/consul.service /etc/systemd/system/consul.service

sudo systemctl enable consul.service
sudo systemctl start consul.service

sleep 10

export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500
export CONSUL_RPC_ADDR=$IP_ADDRESS:8400

# Nomad
## Replace existing Nomad binary if remote file exists
if [[ `wget -S --spider $NOMAD_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $NOMAD_BINARY > nomad.zip
  sudo unzip -o nomad.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/nomad
  sudo chown root:root /usr/local/bin/nomad
fi

## Copy files to correct location
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/nomad-server.hcl
sudo cp $CONFIGDIR/nomad-server.hcl $NOMADCONFIGDIR
sudo cp $CONFIGDIR/nomad.service /etc/systemd/system/nomad.service

## Generate Gossip key
ENCRYPT_KEY=$(nomad operator keygen)
sed -i `s/ENCRYPT_KEY/$ENCRYPT_KEY` $NOMADCONFIGDIR/nomad-server.hcl

## Start Nomad service
sudo systemctl enable nomad.service
sudo systemctl start nomad.service

# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

echo "nameserver $IP_ADDRESS" | tee /etc/resolv.conf.new
cat /etc/resolv.conf | tee --append /etc/resolv.conf.new
mv /etc/resolv.conf.new /etc/resolv.conf

# Add search service.consul at bottom of /etc/resolv.conf
echo "search service.consul" | tee --append /etc/resolv.conf

# Add Docker bridge network IP to /etc/resolv.conf (at the top)
echo "nameserver $DOCKER_BRIDGE_IP_ADDRESS" | sudo tee /etc/resolv.conf.new
cat /etc/resolv.conf | sudo tee --append /etc/resolv.conf.new
sudo mv /etc/resolv.conf.new /etc/resolv.conf

# Set env vars for tool CLIs
echo "export CONSUL_RPC_ADDR=$IP_ADDRESS:8400" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | sudo tee --append /home/$HOME_DIR/.bashrc