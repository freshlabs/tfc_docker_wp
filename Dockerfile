FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chown root:root /tfc-init.sh
RUN chmod a+x /tfc-init.sh

RUN mv -f /wp-cli.local.yml /opt/bitnami/wordpress/wp-cli.local.yml

ENV WP_CLI_CONFIG_PATH="/opt/bitnami/wordpress/wp-cli.local.yml"

# Expose Service Ports
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "nami", "start", "--foreground", "apache" ]