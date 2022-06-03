#!/bin/bash

if ! [ -x "$(command -v wget)" ]; then
  yum -y install wget
fi

wget -qO- https://get.docker.com/ | sh
sudo systemctl enable docker
sudo systemctl start docker

docker run -dt --name ss -p 6443:6443 mritd/shadowsocks -s "-s 0.0.0.0 -p 6443 -m chacha20-ietf-poly1305 -k test123"
