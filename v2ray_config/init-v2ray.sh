#!/bin/bash
set -e

# detect OS via /etc/os-release
OS_ID="unknown"
if [ -r /etc/os-release ]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_LIKE="${ID_LIKE:-}"
fi

case "${OS_ID}:${OS_LIKE}" in
  centos:*|rhel:*|fedora:*|rocky:*|almalinux:*|*:*rhel*|*:*fedora*)
    PKG_FAMILY="rhel"
    ;;
  ubuntu:*|debian:*|*:*debian*)
    PKG_FAMILY="debian"
    ;;
  *)
    if command -v apt-get >/dev/null 2>&1; then
      PKG_FAMILY="debian"
    elif command -v yum >/dev/null 2>&1; then
      PKG_FAMILY="rhel"
    elif command -v dnf >/dev/null 2>&1; then
      PKG_FAMILY="rhel"
    else
      echo "Unsupported OS: ${OS_ID}. Please install wget/curl/docker/docker-compose manually."
      PKG_FAMILY="unknown"
    fi
    ;;
esac

echo "Detected OS: ${OS_ID} (package family: ${PKG_FAMILY})"

pkg_install() {
  case "$PKG_FAMILY" in
    rhel)
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf -y install "$@"
      else
        sudo yum -y install "$@"
      fi
      ;;
    debian)
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
    *)
      echo "Skip install: unsupported package family for $*"
      ;;
  esac
}

# install wget if missing
if ! command -v wget >/dev/null 2>&1; then
  echo "Installing wget..."
  pkg_install wget
fi

# install curl if missing (needed to fetch docker-compose binary)
if ! command -v curl >/dev/null 2>&1; then
  echo "Installing curl..."
  pkg_install curl
fi

# install docker if not exists
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing docker..."
  wget -qO- https://get.docker.com/ | sh
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker is already installed"
fi

# install docker-compose if not exists
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Installing docker-compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  if [ ! -e /usr/bin/docker-compose ]; then
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  fi
else
  echo "Docker-compose is already installed"
fi

# timezone
sudo timedatectl set-timezone Asia/Shanghai || true

docker-compose up -d

# BBR install
#wget –no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
#
#chmod +x bbr.sh
#
#./bbr.sh
