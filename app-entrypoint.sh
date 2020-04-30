#!/bin/bash -e

. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

print_welcome_page

if [[ "$1" == "nami" && "$2" == "start" ]] || [[ "$1" == "/init.sh" ]]; then
#    . /apache-init.sh
#    . /tfc-init.sh
    nami_initialize apache php
    info "Running Automated Install Now... "
#    . /tfc-install.sh
    info "Running Post Install Scripts... "
#    . /post-init.sh
    info "All done, starting FSB... "
fi

exec tini -- "$@"