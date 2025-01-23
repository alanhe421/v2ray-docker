#!/bin/bash

if ! [ -x "$(command -v wget)" ]; then
  yum -y install wget
fi

# install docker if not exists
if ! [ -x "$(command -v docker)" ]; then
  echo "Installing docker..."
  wget -qO- https://get.docker.com/ | sh
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker is already installed"
fi

# install docker-compose if not exists
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Installing docker-compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
else
  echo "Docker-compose is already installed"
fi

# timezone
timedatectl set-timezone Asia/Shanghai

docker-compose up -d

# BBR install
#wget –no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
#
#chmod +x bbr.sh
#
#./bbr.sh
