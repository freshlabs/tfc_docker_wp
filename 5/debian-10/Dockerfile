# Setup Base Image (OS)
FROM docker.io/bitnami/minideb:buster

# Setup Labels
LABEL maintainer="team@freshlabs.group" \
      author="Fresh Labs" \
      sources.OS="bitnami/minideb" \
      sources.OS.release="buster" \
      sources.APP="Wordpress" \
      sources.APP.version="5.5.2" \
      docker.image.version="dev"

# Setup required bitnami Environmental Variables
ENV BITNAMI_PKG_CHMOD="-R g+rwX" \
    HOME="/" \
    PATH="/opt/bitnami/apache/bin:/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/wp-cli/bin:/opt/bitnami/mysql/bin:/opt/bitnami/common/bin:/opt/bitnami/nami/bin:$PATH"

# Copy System Script files to root
COPY prebuildfs /

# Install bitnami required system packages and dependencies
RUN install_packages ca-certificates curl dirmngr gnupg libaudit1 libbsd0 libbz2-1.0 libc6 libcap-ng0 libcom-err2 libcurl4 libexpat1 libffi6 libfftw3-double3 libfontconfig1 libfreetype6 libgcc1 libgcrypt20 libglib2.0-0 libgmp10 libgnutls30 libgomp1 libgpg-error0 libgssapi-krb5-2 libhogweed4 libicu63 libidn2-0 libjemalloc2 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblcms2-2 libldap-2.4-2 liblqr-1-0 libltdl7 liblzma5 libmagickcore-6.q16-6 libmagickwand-6.q16-6 libmcrypt4 libmemcached11 libmemcachedutil2 libncurses6 libnettle6 libnghttp2-14 libonig5 libp11-kit0 libpam0g libpcre3 libpng16-16 libpq5 libpsl5 libreadline7 librtmp1 libsasl2-2 libsqlite3-0 libssh2-1 libssl1.1 libstdc++6 libsybdb5 libtasn1-6 libtidy5deb1 libtinfo6 libunistring2 libuuid1 libx11-6 libxau6 libxcb1 libxdmcp6 libxext6 libxml2 libxslt1.1 libzip4 procps sudo unzip zlib1g grep

# Setup bitnami environment
RUN /build/bitnami-user.sh
RUN /build/install-nami.sh

# Setup required system packages
RUN bitnami-pkg install php-7.4.11-4 --checksum bb6b4cfe19cad2312aeb2606994c2ad403a671ed78b4e49276a206a75e89c491
RUN bitnami-pkg unpack apache-2.4.46-3 --checksum 07991412bb24fc8493228f4bd67b28a77e011242971dcdd687a5d2113ac89bc9
RUN bitnami-pkg install wp-cli-2.4.0-2 --checksum 33c3b53e87e9e433291ac3511e68263c80b43aa4de3dead9502934f506b7f2e6
RUN bitnami-pkg unpack mysql-client-10.3.25-0 --checksum 12528e33966094535a302d557eca3eb1ae7d5c7b8fff4b9e70d96cafedbb5341
RUN bitnami-pkg install libphp-7.4.11-1 --checksum 2a552ec9133bfeea17ee4fa40976499165cc3c6c89e00d483063df083abe4b13
RUN bitnami-pkg install tini-0.19.0-1 --checksum 9b1f1c095944bac88a62c1b63f3bff1bb123aa7ccd371c908c0e5b41cec2528d
RUN bitnami-pkg install gosu-1.12.0-2 --checksum 4d858ac600c38af8de454c27b7f65c0074ec3069880cb16d259a6e40a46bbc50

RUN apt-get update && apt-get upgrade -y && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives
RUN ln -sf /dev/stdout /opt/bitnami/apache/logs/access_log && \
    ln -sf /dev/stderr /opt/bitnami/apache/logs/error_log

# Copy Application script files to root
COPY rootfs /

# Setup App Environmental Variables
ENV ALLOW_EMPTY_PASSWORD="no" \
    APACHE_ENABLE_CUSTOM_PORTS="no" \
    APACHE_HTTPS_PORT_NUMBER="8443" \
    APACHE_HTTP_PORT_NUMBER="8080" \
    BITNAMI_APP_NAME="tfc_wp" \
    BITNAMI_IMAGE_VERSION="5.5.1-debian-10-r12" \
    MARIADB_HOST="mariadb" \
    MARIADB_PORT_NUMBER="3306" \
    MARIADB_ROOT_PASSWORD="" \
    MARIADB_ROOT_USER="root" \
    MYSQL_CLIENT_CREATE_DATABASE_NAME="" \
    MYSQL_CLIENT_CREATE_DATABASE_PASSWORD="" \
    MYSQL_CLIENT_CREATE_DATABASE_PRIVILEGES="ALL" \
    MYSQL_CLIENT_CREATE_DATABASE_USER="" \
    MYSQL_CLIENT_ENABLE_SSL="no" \
    MYSQL_CLIENT_SSL_CA_FILE="" \
    NAMI_PREFIX="/.nami" \
    PHP_MEMORY_LIMIT="256M" \
    SMTP_HOST="" \
    SMTP_PASSWORD="" \
    SMTP_PORT="" \
    SMTP_PROTOCOL="" \
    SMTP_USER="" \
    SMTP_USERNAME="" \
    WORDPRESS_BLOG_NAME="User's Blog!" \
    WORDPRESS_BLOG_URL="localhost" \
    WORDPRESS_DATABASE_NAME="bitnami_wordpress" \
    WORDPRESS_DATABASE_PASSWORD="" \
    WORDPRESS_DATABASE_SSL_CA_FILE="" \
    WORDPRESS_DATABASE_USER="bn_wordpress" \
    WORDPRESS_EMAIL="user@example.com" \
    WORDPRESS_EXTRA_WP_CONFIG_CONTENT="" \
    WORDPRESS_FIRST_NAME="FirstName" \
    WORDPRESS_HTACCESS_OVERRIDE_NONE="yes" \
    WORDPRESS_HTACCESS_PERSISTENCE_ENABLED="no" \
    WORDPRESS_HTTPS_PORT="8443" \
    WORDPRESS_HTTP_PORT="8080" \
    WORDPRESS_LAST_NAME="LastName" \
    WORDPRESS_PASSWORD="bitnami" \
    WORDPRESS_SCHEME="http" \
    WORDPRESS_SKIP_INSTALL="no" \
    WORDPRESS_TABLE_PREFIX="wp_" \
    WORDPRESS_USERNAME="user" \
    INSTALL_FORCE_CLEANUP="no" \
    MIGRATE_DB_TO_LOCAL="no" \
    MIGRATE_MARIADB_HOST="host.docker.internal" \
    MIGRATE_MARIADB_PORT_NUMBER="3306" \
    MIGRATE_MARIADB_ROOT_USER="fpcloud" \
    MIGRATE_MARIADB_ROOT_PASSWORD="" \
    MIGRATE_WORDPRESS_DATABASE_NAME="bitnami_wordpress" \
    MIGRATE_WORDPRESS_DATABASE_USER="bn_wordpress" \
    MIGRATE_WORDPRESS_DATABASE_PASSWORD="" \
    MIGRATE_WORDPRESS_TABLE_PREFIX="" \
    IONCUBE_ENABLED="0"

# Expose Service Ports
EXPOSE 8080 8443

# Setup folders and permissions
RUN /build/setup-tfc_wp.sh

# Exit root and run as unpriviledge user
USER 1001

# Run Entrypoint Script
ENTRYPOINT [ "/app-entrypoint.sh" ]

# Run Apache service to start listening for requests
CMD [ "httpd", "-f", "/opt/bitnami/apache/conf/httpd.conf", "-DFOREGROUND" ]
