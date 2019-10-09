FROM bitnami/wordpress
LABEL maintainer "Bitnami <containers@bitnami.com>"

# Install custom or additional server modules
RUN install_packages unzip nano vim

# Copy Over needed files
COPY scripts /

EXPOSE 80 443

ENTRYPOINT [ "/tfc-init.sh" ]
CMD [ "nami", "start", "--foreground", "apache" ]