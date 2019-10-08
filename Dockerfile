FROM bitnami/wordpress

ENTRYPOINT [ "/app-entrypoint.sh" ]

# TFC CUSTOM COMMANDS #

# Install custom or additional server modules
RUN install_packages unzip nano vim

# TFC CUSTOM COMMANDS #
