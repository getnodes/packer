#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# --- Pritunl setup ---
sudo tee /etc/apt/sources.list.d/mongodb-org.list << EOF
deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse
EOF

sudo tee /etc/apt/sources.list.d/openvpn.list << EOF
deb [ signed-by=/usr/share/keyrings/openvpn-repo.gpg ] https://build.openvpn.net/debian/openvpn/stable noble main
EOF

sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb [ signed-by=/usr/share/keyrings/pritunl.gpg ] https://repo.pritunl.com/stable/apt noble main
EOF

sudo apt --assume-yes install gnupg

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor --yes
curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg | sudo gpg -o /usr/share/keyrings/openvpn-repo.gpg --dearmor --yes
curl -fsSL https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc | sudo gpg -o /usr/share/keyrings/pritunl.gpg --dearmor --yes

sudo apt update
sudo apt --assume-yes install pritunl openvpn mongodb-org wireguard wireguard-tools

sudo ufw disable

sudo systemctl enable pritunl mongod

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

sudo apt --assume-yes install fail2ban

sudo tee /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh, 1422
banaction = iptables-multiport
EOF

sudo systemctl enable fail2ban

# --- Admin user ---
useradd --create-home --shell /bin/bash admin
usermod -aG sudo admin
echo "admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admin
chmod 0440 /etc/sudoers.d/admin
mkdir -p /home/admin/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgIai+2wmew3nLm4JKHnNqH7FE5p/OdPifLLEKbkjL/" > /home/admin/.ssh/authorized_keys
chmod 700 /home/admin/.ssh
chmod 600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh

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
