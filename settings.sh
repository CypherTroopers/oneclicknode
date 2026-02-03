#!/bin/bash
set -euo pipefail

apt-get update
apt-get full-upgrade -y
apt-get autoremove -y
apt-get autoclean -y
if [ -f /etc/gai.conf ]; then
  sed -i -E 's/^[#[:space:]]*precedence[[:space:]]+::ffff:0:0\/96[[:space:]]+100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf || true
fi

apt-get install -y --no-install-recommends \
  ca-certificates curl wget git nano rsync ufw \
  build-essential gcc cmake m4 bzip2 texinfo pkg-config \
  libssl-dev openssl libgmp-dev libc-dev \
  python3 python3-venv python3-pip python3-dev \
  nodejs npm pcscd zstd

# Node: switch to latest stable via "n"
npm install -g n
n stable

apt-get purge -y nodejs npm
apt-get autoremove -y

export PATH="/usr/local/bin:$PATH"
grep -q '^export PATH=/usr/local/bin:\$PATH' /root/.bashrc || echo 'export PATH=/usr/local/bin:$PATH' >> /root/.bashrc
hash -r

npm install -g pm2

ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp
ufw allow 8000/tcp
ufw allow 6000/tcp
ufw allow 6000/udp
ufw allow 7100/tcp
ufw allow 7100/udp
ufw allow 7002/tcp
ufw allow 7002/udp
ufw allow 30303/tcp
ufw allow 30303/udp
ufw allow 30301/tcp
ufw allow 30301/udp
ufw allow 8546/tcp
ufw allow 9090/tcp
ufw allow 9090/udp
ufw allow 9600/tcp
ufw allow 9600/udp

ufw --force enable
ufw status numbered || true

GO_VER="1.25.6"
GO_TGZ="go${GO_VER}.linux-amd64.tar.gz"
wget -4 -O "/tmp/${GO_TGZ}" "https://go.dev/dl/${GO_TGZ}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "/tmp/${GO_TGZ}"
rm -f "/tmp/${GO_TGZ}"

echo "🧩 Step 3: Configure Go environment variables"
export PATH=/usr/local/go/bin:$PATH
export GOPATH=/root/go
export GO111MODULE=off
go env -w GO111MODULE=off

grep -q '/usr/local/go/bin' /root/.bashrc || echo 'export PATH=/usr/local/go/bin:$PATH' >> /root/.bashrc
grep -q '^export GOPATH=' /root/.bashrc || echo 'export GOPATH=/root/go' >> /root/.bashrc
grep -q '^export GO111MODULE=' /root/.bashrc || echo 'export GO111MODULE=off' >> /root/.bashrc
mkdir -p "$GOPATH/src"

go version
node -v
npm -v
pm2 -v
