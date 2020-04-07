FROM bitnami/wordpress:5.4.0
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
USER 0
RUN install_packages nano vim
USER 1001

# Copy Over needed files
COPY scripts /

# Adjust script permissions
USER 0
RUN chown 1001:daemon /tfc-init.sh
RUN chown 1001:daemon /wp-cli.local.yml
RUN chmod a+x /tfc-init.sh
USER 1001

RUN /tfc-init.sh

# Expose Service Ports
#EXPOSE 8080 8443

# Execute scripts
#ENTRYPOINT [ "./tfc-init.sh" ]
#CMD [ "httpd", "-f", "/opt/bitnami/apache/conf/httpd.conf", "-DFOREGROUND" ]