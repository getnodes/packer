#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

packer fmt -check .

read -rs -p "HCLOUD_TOKEN: " HCLOUD_TOKEN
echo

export HCLOUD_TOKEN

packer init .
packer validate .
packer build .
