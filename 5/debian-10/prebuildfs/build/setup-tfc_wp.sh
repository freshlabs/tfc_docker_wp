#!/bin/bash

# Setup Structure
mkdir -p /bitnami/tfc_wp
mkdir -p /opt/bitnami/tfc_wp
mkdir -p /opt/bitnami/tfc_wp/tmp/
mkdir -p /bitnami/tfc_wp/.wp-cli/cache

# Setup Permissions
chmod 775 /opt/bitnami/tfc_wp
chmod 775 /bitnami/tfc_wp
chown -R 1001 /opt/bitnami/tfc_wp
chown -R 1001 /bitnami/tfc_wp
chown -R 1001:1001 /bitnami/tfc_wp/.wp-cli