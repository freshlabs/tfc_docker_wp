FROM bitnami/wordpress:5.4.0
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
USER 0
RUN install_packages nano vim

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chown 1001:daemon /tfc-init.sh
RUN chown 1001:daemon /wp-cli.local.yml
RUN chmod a+x /tfc-init.sh

# Expose Service Ports
ENV APACHE_HTTP_PORT_NUMBER=80
ENV APACHE_HTTPS_PORT_NUMBER=443
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "httpd", "-f", "/opt/bitnami/apache/conf/httpd.conf", "-DFOREGROUND" ]