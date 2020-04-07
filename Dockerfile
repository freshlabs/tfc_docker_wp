FROM bitnami/wordpress:5.4.0
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
USER 0
RUN install_packages nano vim
USER 1001

# Copy Over needed files
COPY scripts /

# Adjust script permissions
RUN chmod a+x /tfc-init.sh

# Expose Service Ports
EXPOSE 80 443

# Execute scripts
ENTRYPOINT [ "./tfc-init.sh" ]
CMD [ "httpd", "-f", "/opt/bitnami/apache/conf/httpd.conf", "-DFOREGROUND" ]