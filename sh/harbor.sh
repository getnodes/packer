#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Docker
curl -fsSL https://get.docker.com | sh

# Harbor release
wget https://github.com/goharbor/harbor/releases/download/v2.14.4/harbor-online-installer-v2.14.4.tgz
tar xzvf harbor-online-installer-v2.14.4.tgz

# HTTPS
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 36500 \
  -subj "/C=TR/ST=Istanbul/L=Istanbul/O=getnodes/OU=devops/CN=GetNodes Harbor Root CA" \
  -key ca.key \
  -out ca.crt

openssl genrsa -out harbor.getnodes.io.key 4096
openssl req -sha512 -new \
    -subj "/C=TR/ST=Istanbul/L=Istanbul/O=getnodes/OU=devops/CN=harbor.getnodes.io" \
    -key harbor.getnodes.io.key \
    -out harbor.getnodes.io.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.getnodes.io
DNS.2=harbor.getnodes
DNS.3=harbor
EOF

openssl x509 -req -sha512 -days 36500 \
  -extfile v3.ext \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in harbor.getnodes.io.csr \
  -out harbor.getnodes.io.crt

mkdir -p /data/cert
mkdir -p /etc/docker/certs.d/harbor.getnodes.io

cp harbor.getnodes.io.crt /data/cert/
cp harbor.getnodes.io.key /data/cert/
openssl x509 -inform PEM -in harbor.getnodes.io.crt -out harbor.getnodes.io.cert
cp harbor.getnodes.io.cert /etc/docker/certs.d/harbor.getnodes.io/
cp harbor.getnodes.io.key /etc/docker/certs.d/harbor.getnodes.io/
cp ca.crt /etc/docker/certs.d/harbor.getnodes.io/

systemctl restart docker

# Harbor setup
cd harbor

sudo tee harbor.yml << EOF
hostname: harbor.getnodes.io
http:
  port: 80
https:
  port: 443
  certificate: /data/cert/harbor.getnodes.io.crt
  private_key: /data/cert/harbor.getnodes.io.key
harbor_admin_password: Harbor12345
database:
  password: tRhHVjRxzXfdubRsvCyB5rerABeT
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  skip_java_db_update: false
  db_repository: ghcr.io/aquasecurity/trivy-db
  java_db_repository: ghcr.io/aquasecurity/trivy-java-db
  offline_scan: true
  security_check: vuln
  insecure: false
  timeout: 5m0s
jobservice:
  max_job_workers: 10
  max_job_duration_hours: 24
  job_loggers:
    - STD_OUTPUT
    - FILE
  logger_sweeper_duration: 1 #days
notification:
  webhook_job_max_retry: 3
  webhook_job_http_client_timeout: 3 #seconds
log:
  level: warning
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.14.4
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
metric:
  enabled: false
  port: 9090
  path: /metrics
upload_purging:
  enabled: true
  age: 168h
  interval: 24h
  dryrun: false
cache:
  enabled: false
  expire_hours: 24
EOF

sudo ./install.sh --with-trivy
