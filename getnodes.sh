#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# --- SSH hardening ---
sudo tee /etc/ssh/sshd_config.d/ssh-hardening.conf << EOF
PermitRootLogin no
PasswordAuthentication no
Port 1422
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
MaxAuthTries 2
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers admin
EOF

# --- Clean up ---
cloud-init clean --logs --machine-id --seed --configs all
rm -rf /run/cloud-init/*
rm -rf /var/lib/cloud/*
export DEBIAN_FRONTEND=noninteractive
apt-get -y autopurge
apt-get -y clean
rm -rf /var/lib/apt/lists/*
journalctl --flush
journalctl --rotate --vacuum-time=0
find /var/log -type f -exec truncate --size 0 {} \; # truncate system logs
find /var/log -type f -name '*.[1-9]' -delete # remove archived logs
find /var/log -type f -name '*.gz' -delete # remove compressed archived logs
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
fstrim --all || true
sync
