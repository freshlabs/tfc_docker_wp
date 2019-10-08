FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chmod +x /tfc-init.sh

# Execute Script
ENTRYPOINT [ "/tfc-init.sh" ]