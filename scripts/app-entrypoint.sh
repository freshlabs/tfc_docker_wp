#!/bin/bash -e

. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

print_welcome_page

if [[ "$1" == "nami" && "$2" == "start" ]] || [[ "$1" == "/init.sh" ]]; then
  . /wordpress-init.sh
  nami_initialize apache php mysql-client wordpress
  info "Starting wordpress... "
fi

info "Started executing custom TFC Script"
. /tfc-init.sh
info "Finished executing custom TFC Script"

exec tini -- "$@"
