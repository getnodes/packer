#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

sudo apt update
sudo apt --assume-yes install haproxy keepalived

curl -fsSL -o /tmp/hcloud.deb https://github.com/hetznercloud/cli/releases/download/v1.65.0/hcloud-cli_1.65.0_amd64.deb
sudo apt --assume-yes install /tmp/hcloud.deb
rm -f /tmp/hcloud.deb
