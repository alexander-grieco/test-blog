#!/bin/bash

set -e

HOME_DIR=ubuntu

echo "Waiting for cloud-init to update /etc/apt/sources.list"
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

# # Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

cd /ops

# Dependencies
sudo apt-get update

sudo apt-get install -y software-properties-common unzip tree redis-tools jq curl tmux dnsmasq

# Consul Variables
CONSULVERSION="1.9.5"
CONSULDOWNLOAD=https://releases.hashicorp.com/consul/${CONSULVERSION}/consul_${CONSULVERSION}_linux_amd64.zip
CONSULCONFIGDIR=/etc/consul.d
CONSULDIR=/opt/consul

# Nomad Variables
NOMADVERSION="1.0.4"
NOMADDOWNLOAD=https://releases.hashicorp.com/nomad/${NOMADVERSION}/nomad_${NOMADVERSION}_linux_amd64.zip
NOMADCONFIGDIR=/etc/nomad.d
NOMADDIR=/opt/nomad

CNIVERSION=0.9.1
CNIDOWNLOAD=https://github.com/containernetworking/plugins/releases/download/v${CNIVERSION}/cni-plugins-linux-amd64-v${CNIVERSION}.tgz
CNIDIR=/opt/cni

# Disable the firewall
sudo ufw disable || echo "ufw not installed"

# install Consul
curl -sL -o consul.zip ${CONSULDOWNLOAD}
sudo unzip consul.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul

# configure Consul directories
sudo mkdir -p ${CONSULCONFIGDIR}
sudo chmod 755 ${CONSULCONFIGDIR}
sudo mkdir -p ${CONSULDIR}
sudo chmod 755 ${CONSULDIR}


# install Nomad
curl -L $NOMADDOWNLOAD > nomad.zip
sudo unzip nomad.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/nomad
sudo chown root:root /usr/local/bin/nomad
nomad version
nomad -autocomplete-install           # enable autocomplete
complete -C /usr/local/bin/nomad nomad

#configure Nomad directories
sudo mkdir -p $NOMADCONFIGDIR
sudo chmod 755 $NOMADCONFIGDIR
sudo mkdir -p $NOMADDIR
sudo chmod 755 $NOMADDIR

# Docker
distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
sudo apt-get install -y apt-transport-https ca-certificates gnupg2
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

# CNI plugins
curl -sL -o cni-plugins.tgz ${CNIDOWNLOAD}
sudo mkdir -p ${CNIDIR}/bin
sudo tar -C ${CNIDIR}/bin -xzf cni-plugins.tgz


# certs
CERTDIR=/ops/certs
CONFIGCERTDIR=$NOMADDIR/tls/certs
sudo mkdir -p $CONFIGCERTDIR
sudo cp $CERTDIR/nomad-ca.pem $CONFIGCERTDIR
sudo cp $CERTDIR/server.pem $CONFIGCERTDIR
sudo cp $CERTDIR/server-key.pem $CONFIGCERTDIR
sudo cp $CERTDIR/client.pem $CONFIGCERTDIR
sudo cp $CERTDIR/client-key.pem $CONFIGCERTDIR
sudo cp $CERTDIR/cli.pem $CONFIGCERTDIR
sudo cp $CERTDIR/cli-key.pem $CONFIGCERTDIR
sudo chmod -R 755 $CONFIGCERTDIR

# set cert environment variables
echo "export NOMAD_CACERT=$CONFIGCERTDIR/nomad-ca.pem" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_CLIENT_CERT=$CONFIGCERTDIR/cli.pem" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_CLIENT_KEY=$CONFIGCERTDIR/cli-key.pem" | sudo tee --append /home/$HOME_DIR/.bashrc


echo 'debconf debconf/frontend select Dialog' | sudo debconf-set-selections
