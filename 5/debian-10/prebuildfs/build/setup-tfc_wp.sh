#!/bin/bash

# Create non-root user (this is only required for migrating existing bitnami images, can otherwise be removed)
#useradd -ms /bin/bash 1001
#usermod -g root 1001
#echo '1001 ALL=NOPASSWD: ALL' >> /etc/sudoers
# remove or comment out this block once everything has been migrated

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


