#!/bin/bash -e

. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

info "Creating Environment File Structure"
mkdir -p /bitnami/tfc_wp
mkdir -p /opt/bitnami/tfc_wp
mkdir -p /opt/bitnami/tfc_wp/tmp/
mkdir -p /bitnami/tfc_wp/.wp-cli/cache

info "Fixing permissions"
chmod 775 /opt/bitnami/tfc_wp
chmod 775 /bitnami/tfc_wp
chown -R 1001 /opt/bitnami/tfc_wp
chown -R 1001 /bitnami/tfc_wp
chown -R 1001:1001 /bitnami/tfc_wp/.wp-cli