FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim

ENTRYPOINT [ "/app-entrypoint.sh" ]