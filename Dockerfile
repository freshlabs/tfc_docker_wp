FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chown root:root /tfc-init.sh
RUN chmod a+x /tfc-init.sh

RUN cp -rf /wp-cli.local.yml /opt/bitnami/wp-cli/conf/wp-cli.yml

ENV WP_CLI_CONFIG_PATH="/opt/bitnami/wp-cli/conf/wp-cli.yml"

# Expose Service Ports
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "nami", "start", "--foreground", "apache" ]