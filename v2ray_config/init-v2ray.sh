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
      echo "Unsupported OS: ${OS_ID}. Please install wget/curl/docker/docker compose manually."
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
      return 1
      ;;
  esac
}

# install wget if missing
if ! command -v wget >/dev/null 2>&1; then
  echo "Installing wget..."
  pkg_install wget
fi

# install curl if missing (needed to fetch Docker/Compose installers)
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

install_compose_plugin_binary() {
  local os arch plugin_dir plugin_path
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "${arch}" in
    x86_64|amd64)
      arch="x86_64"
      ;;
    aarch64|arm64)
      arch="aarch64"
      ;;
    armv7l|armv7)
      arch="armv7"
      ;;
    *)
      echo "Unsupported architecture for Docker Compose plugin binary: ${arch}"
      return 1
      ;;
  esac

  plugin_dir="/usr/local/lib/docker/cli-plugins"
  plugin_path="${plugin_dir}/docker-compose"
  sudo mkdir -p "${plugin_dir}"
  sudo curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-${os}-${arch}" -o "${plugin_path}"
  sudo chmod +x "${plugin_path}"
}

# install Docker Compose v2 plugin if missing
if ! docker compose version >/dev/null 2>&1; then
  echo "Installing Docker Compose v2 plugin..."
  if ! pkg_install docker-compose-plugin; then
    install_compose_plugin_binary
  fi
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is not available. Please install the docker compose plugin manually."
  exit 1
fi

# timezone
sudo timedatectl set-timezone Asia/Shanghai || true

docker compose up -d

# BBR install
#wget –no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
#
#chmod +x bbr.sh
#
#./bbr.sh
