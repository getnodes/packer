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
