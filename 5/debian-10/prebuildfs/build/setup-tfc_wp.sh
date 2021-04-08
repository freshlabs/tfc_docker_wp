#!/bin/bash

# Create non-root user (this is only required for migrating existing bitnami images, can otherwise be removed)
# info "Checking for our non-root user"
# if id 1001 &>/dev/null; then
#   info "User 1001 already exists"
# else
#   info 'User 1001 not found, creating'
#   useradd -ms /bin/bash 1001 || true
#   usermod -g root 1001 || true
#   echo '1001 ALL=NOPASSWD: ALL' >> /etc/sudoers
# fi

# Setup folders and permissions

info "Setting up folder /bitnami/tfc_wp"
mkdir -p /bitnami/tfc_wp
chmod 775 /bitnami/tfc_wp
chown -R 1001 /bitnami/tfc_wp

info "Setting up folder /bitnami/tfc_wp/tmp"
mkdir -p /bitnami/tfc_wp/tmp
chmod 775 /bitnami/tfc_wp/tmp
chown -R 1001 /bitnami/tfc_wp/tmp

info "Setting up folder /bitnami/tfc_wp/.wp-cli"
mkdir -p /bitnami/tfc_wp/.wp-cli/cache
chmod 775 /bitnami/tfc_wp/.wp-cli
chmod 775 /bitnami/tfc_wp/.wp-cli/cache
chown -R 1001:1001 /bitnami/tfc_wp
chown -R 1001:1001 /bitnami/tfc_wp/.wp-cli

info "Setting up folder /opt/bitnami/tfc_wp"
mkdir -p /opt/bitnami/tfc_wp
chmod 775 /opt/bitnami/tfc_wp
chown -R 1001 /opt/bitnami/tfc_wp


