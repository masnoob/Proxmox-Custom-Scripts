#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://infisical.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# ------------------------------------------------------------------------------
# External PostgreSQL Configuration
# ------------------------------------------------------------------------------
PG_DB_HOST="${PG_DB_HOST:-192.168.0.72}"
PG_DB_PORT="${PG_DB_PORT:-5432}"
PG_DB_NAME="${PG_DB_NAME:-infisical}"
PG_DB_USER="${PG_DB_USER:-infisical}"
PG_DB_PASS="${PG_DB_PASS:-infisical}"

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  redis \
  postgresql-client
msg_ok "Installed Dependencies"

msg_info "Setting up Infisical Repository"
setup_deb822_repo \
  "infisical" \
  "https://artifacts-infisical-core.infisical.com/infisical.gpg" \
  "https://artifacts-infisical-core.infisical.com/deb" \
  "stable"
msg_ok "Setup Infisical repository"

msg_info "Setting up Infisical"
AUTH_SECRET="$(openssl rand -base64 32 | tr -d '\n')"
ENC_KEY="$(openssl rand -hex 16 | tr -d '\n')"
$STD apt install -y infisical-core
mkdir -p /etc/infisical
cat <<EOF >/etc/infisical/infisical.rb
infisical_core['ENCRYPTION_KEY'] = '$ENC_KEY'
infisical_core['AUTH_SECRET'] = '$AUTH_SECRET'
infisical_core['HOST'] = '$LOCAL_IP'
infisical_core['DB_CONNECTION_URI'] = 'postgres://${PG_DB_USER}:${PG_DB_PASS}@${PG_DB_HOST}:${PG_DB_PORT}/${PG_DB_NAME}'
infisical_core['REDIS_URL'] = 'redis://localhost:6379'
EOF

cat <<EOF >~/infisical.creds
PostgreSQL Credentials
Host: $PG_DB_HOST
Port: $PG_DB_PORT
Database: $PG_DB_NAME
User: $PG_DB_USER
Password: $PG_DB_PASS
EOF

$STD infisical-ctl reconfigure
msg_ok "Setup Infisical"

motd_ssh
customize
cleanup_lxc
