FROM bitnami/wordpress:5.4.0
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN apt-get install nano vim -y --force-yes -qq

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chown root:root /tfc-init.sh
RUN chown root:root /wp-cli.local.yml
RUN chmod a+x /tfc-init.sh

# Expose Service Ports
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "nami", "start", "--foreground", "apache" ]