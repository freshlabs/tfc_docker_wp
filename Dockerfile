FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim sudo

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chown root:root /tfc-init.sh
RUN chmod a+x /tfc-init.sh

# Expose Service Ports
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "nami", "start", "--foreground", "apache" ]