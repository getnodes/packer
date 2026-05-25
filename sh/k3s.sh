#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

sudo curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.35.5%2Bk3s1/k3s
sudo chmod +x /usr/local/bin/k3s

curl -Lo /opt/install.sh https://get.k3s.io
chmod +x /opt/install.sh

curl -L -o k3s-airgap-images-amd64.tar.zst "https://github.com/k3s-io/k3s/releases/download/v1.35.5%2Bk3s1/k3s-airgap-images-amd64.tar.zst"
sudo mkdir -p /var/lib/rancher/k3s/agent/images/
sudo cp k3s-airgap-images-amd64.tar.zst /var/lib/rancher/k3s/agent/images/k3s-airgap-images-amd64.tar.zst
