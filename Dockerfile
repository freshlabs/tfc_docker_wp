FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim sudo

# Install wp-cli
RUN bitnami-pkg install wp-cli-2.4.0-0 --checksum 3bf68efbc817708e466a6ba32dd8ec46408931c38b7e568c76a7bc2c76319578

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