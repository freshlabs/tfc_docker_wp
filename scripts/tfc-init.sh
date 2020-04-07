#!/bin/bash -e

# this is from the original app-entrypoint.sh
# https://github.com/bitnami/bitnami-docker-wordpress/blob/master/5/debian-9/rootfs/app-entrypoint.sh
. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

print_welcome_page

info "Welcome to The Fresh Cloud, we just need to setup some additional things... "

# this seems redundant but necessary currently since the file at the root appears to be ignored by the nami_initialize wordpress function below
info "Setup wp-cli config file ..."
sed -i '$ a\skip-themes: true' /opt/bitnami/wp-cli/conf/wp-cli.yml
sed -i '$ a\skip-plugins: true' /opt/bitnami/wp-cli/conf/wp-cli.yml
info "Setup wp-cli config completed"

if [[ "$1" == "nami" && "$2" == "start" ]] || [[ "$1" == "/init.sh" ]]; then
  . /wordpress-init.sh
  nami_initialize apache php mysql-client wordpress || true
  info "Starting wordpress... "
fi
# this is from the original app-entrypoint.sh

info "Giving group write access to wp-config ... "
chmod g+rwX /opt/bitnami/wordpress/wp-config.php
info "Group write access given."

FCPPATH="/opt/bitnami/wordpress/wp-content/plugins/fresh-connect/";
INSTALLFILE="/opt/bitnami/wordpress/wp-content/.alreadyinstalled";

if [ -d "$FCPPATH" ]; then
    info "Looks like a Fresh Connect Plugin already existed.  We need to delete it and install the latest version first."
    sudo rm -rf "$FCPPATH"
fi

info "Start Installing custom plugins and grabing FCK's ..."
sudo -u daemon -- curl -s -L https://github.com/freshlabs/fresh-connect-wp-plugin/archive/master.zip -o /tmp/fresh-connect.zip
sudo -u daemon -- unzip -o -q /tmp/fresh-connect.zip -d /opt/bitnami/wordpress/wp-content/plugins/
sudo -u daemon -- mv -f /opt/bitnami/wordpress/wp-content/plugins/fresh-connect-wp-plugin-master "$FCPPATH"
info "Finished Installing custom plugins and grabing FCK's"

info "Start Installing additional plugins ..."
rm -rf /bitnami/wordpress/wp-content/plugins/google-pagespeed-insights/
sudo -u daemon -- wp plugin install https://downloads.wordpress.org/plugin/google-pagespeed-insights.zip --force --activate || true
info "Finished Installing additional plugins"

info "Activating custom plugins and grabing FCK's ..."
PLUGINSACTIVATION=$(sudo -u daemon -- wp plugin activate fresh-connect --quiet)

# this is only executed on the first install
if [ ! -f "$INSTALLFILE" ]; then
    info "Start removing Bitnami Default Plugins ..."
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/akismet/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/all-in-one-seo-pack/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/all-in-one-wp-migration/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/wp-cloud-mgmt-console/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/google-analytics-for-wordpress/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/jetpack/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/simple-tags/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/w3-total-cache/
    rm -rf /opt/bitnami/wordpress/wp-content/plugins/wordpress-mu-domain-mapping/
    rm -f /opt/bitnami/wordpress/wp-content/plugins/hello.php
    info "Finished removing Bitnami Default Plugins"
fi

echo "Fresh Connect Key >>"

if [[ $PLUGINSACTIVATION == *"Error"* ]]; then

    echo "Error: FCK could not be obtained at this time because the FCK Plugin could not be installed or activated correctly during deployment."

else

    FRESHCONNECTKEYS=$(wp option get fp_connection_keys --allow-root)

    echo "$FRESHCONNECTKEYS"

fi

echo "<< Fresh Connect Key"

info "Setup placeholder file used to identify first install..."
touch "$INSTALLFILE"
info "Setup placeholder file completed"

info "Setup Special permissions on needed files"
touch /opt/bitnami/wordpress/.htaccess
touch /opt/bitnami/wordpress/ads.txt
chmod g+rwX /opt/bitnami/wordpress/wp-config.php
chmod g+rwX /opt/bitnami/wordpress/.htaccess
chmod g+rwX /opt/bitnami/wordpress/ads.txt
chown -R bitnami:daemon /opt/bitnami/wordpress
find /opt/bitnami/wordpress/wp-content/ -type d -exec chmod 775 {} \;
find /opt/bitnami/wordpress/wp-content/ -type f -exec chmod 664 {} \;
chown -R bitnami:daemon /bitnami/wordpress/wp-content/
info "Finished Setup Special permissions on needed files"

info "Custom commands completed"

exec tini -- "$@"