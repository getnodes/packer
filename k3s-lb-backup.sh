#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# --- HAProxy + KeepAlived setup ---
sudo apt update
sudo apt --assume-yes install haproxy keepalived

sudo tee /etc/haproxy/haproxy.cfg << EOF
frontend k3s-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend k3s-backend

backend k3s-backend
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s
    server server-1 10.42.2.4:6443 check
    server server-2 10.42.2.5:6443 check
    server server-3 10.42.2.6:6443 check
EOF

sudo tee /etc/keepalived/keepalived.conf << EOF
global_defs {
    enable_script_security
    script_user root
}

vrrp_script chk_haproxy {
    script 'killall -0 haproxy' # faster than pidof
    interval 2
}

vrrp_instance haproxy-vip {
    interface eth1
    state BACKUP
    priority 100

    virtual_router_id 51

    virtual_ipaddress {
        10.42.1.10/24
    }

    track_script {
        chk_haproxy
    }
}
EOF

sudo systemctl enable haproxy keepalived

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
