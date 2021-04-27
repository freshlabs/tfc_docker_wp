#!/bin/bash -e

# Require bitnami helper files and functions
. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

# Web Root
ROOTPATH="/bitnami/tfc_wp";

# Old volatile directory (deprecated)
OLDROOTPATH="/opt/bitnami/tfc_wp";

# Install File Location
INSTALLFILE="$ROOTPATH/.alreadyinstalled";
# Latest Version File Location
LATESTVERSION="$ROOTPATH/.lastversioninstalled";
# WP Temporary Dir Location
WPTEMPDIR="$ROOTPATH/tmp";
# WP Content Dir Location
WPCONTENTDIR="$ROOTPATH/wp-content";
# Migration flag (overritten on an actual migration)
MIGRATIONFLAG="no";
# Add Custom plugins on a regular run?
ADDCUSTOMPLUGINS="no";
# Remove default plugins
REMOVEDEFAULTPLUGINS="yes"
# Stop defining variables


# Add IonCube if enabled
# Needs updating when the PHP version updates
if [ $IONCUBE_ENABLED = "1" ]; then
  info "ionCube is enabled for this website, adding the loader file and config entry ..."
  curl -L https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip -o /tmp/ioncube.zip
  mkdir -p /tmp/ioncube
  chmod 777 /tmp/ioncube
  chown -R 1001 /tmp/ioncube
  unzip -o -qq /tmp/ioncube.zip
  cp /tmp/ioncube/ioncube_loader_lin_7.4.so /opt/bitnami/php/lib/php/extensions/
  echo "zend_extension = /opt/bitnami/php/lib/php/extensions/ioncube_loader_lin_7.4.so" >> /opt/bitnami/php/lib/php.ini
  rm -rf /tmp/ioncube.zip
  rm -rf /tmp/ioncube
  info "ionCube loader install completed"
fi


# Are we forcing a fresh start?
if [ $INSTALL_FORCE_CLEANUP = "yes" ]; then

    info "A reinstall flag was found, we are deleting the $INSTALLFILE file to force it ..."
    rm -rf "$INSTALLFILE"
    info "Removing .alreadyinstalled file completed."

fi

# Setup wp-cli cache to our permanent storage and export the variable
info "Set wp-cli cache dir at persistent storage"
export WP_CLI_CACHE_DIR="$ROOTPATH"/.wp-cli/cache

# Download WP Core files to disposable storage
if [ ! -f "$LATESTVERSION" ]; then

  VERSIONONFILE="5.7"

else

  VERSIONONFILE=$(grep . $LATESTVERSION)

  if [ "$VERSIONONFILE" = "5.5.3-alpha-49449" ]; then

  VERSIONONFILE="5.5.3"

  fi

fi

info "Downloading WP (version: $VERSIONONFILE) to Disposable Storage"
wp core download --version="$VERSIONONFILE" --locale=en_US --path="$ROOTPATH" --force

info "Setting up folder /bitnami/tfc_wp/tmp"
mkdir -p /bitnami/tfc_wp/tmp

info "Resetting permissions for /bitnami/tfc_wp/tmp"
chown -R 1001 /bitnami/tfc_wp || true
chmod -R 775 /bitnami/tfc_wp || true

# We need to identify if we are dealing with a new install (or cleanup) or if this is an existing build
if [ ! -f "$INSTALLFILE" ]; then

  info "Install file does not exist, so we are going for a full blank install"

  # Create the WP Config File
  info "Create WP Config"
  wp config create --dbhost="${MARIADB_HOST}:${MARIADB_PORT_NUMBER}" --dbname="${WORDPRESS_DATABASE_NAME}" --dbprefix="${WORDPRESS_TABLE_PREFIX}" --dbcharset=utf8 --dbuser="${WORDPRESS_DATABASE_USER}" --dbpass="${WORDPRESS_DATABASE_PASSWORD}" --locale=en_US --skip-check --path="$ROOTPATH" --force

  # Make some changes to wp-config file
  info "Using SED to adjust our wp-config.php file with some additional settings"
  sed -i "s/dirname( __FILE__ )/'"${ROOTPATH//'/'/'\/'}"'/g" "$ROOTPATH"/wp-config.php

  # Append some additional data to wp-config file
  info "Append some additional functions to wp-config.php file"
  sed -i "\$aif ( \!defined( 'WP_CLI' ) ) \{\n\/\/  Disable pingback.ping xmlrpc method to prevent WordPress from participating in DDoS attacks\n\/\/  More info at: https://wiki.bitnami.com/Applications/Bitnami_WordPress#XMLRPC_and_Pingback\n\n// remove x-pingback HTTP header\nadd_filter('wp_headers', function(\$headers) \{\n            unset(\$headers['X-Pingback']);\n            return \$headers;\n           \});\n// disable pingbacks\nadd_filter( 'xmlrpc_methods', function( \$methods ) \{\n             unset( \$methods['pingback.ping'] );\n             return \$methods;\n           \});\n}" "$ROOTPATH"/wp-config.php

  # Run WP Install Procedure
  info "Let us run the install now"
  #wp core install --url=localhost --title="aaaa" --admin_user="momon" --admin_password="1234" --admin_email="redstormj@gmail.com" --path="/opt/bitnami/tfc_wp" --skip-email
  wp core install --url="${WORDPRESS_BLOG_URL}" --title="${WORDPRESS_BLOG_NAME}" --admin_user="${WORDPRESS_USERNAME}" --admin_password="${WORDPRESS_PASSWORD}" --admin_email="${WORDPRESS_EMAIL}" --path="$ROOTPATH" --skip-email

  info "Creating placeholder files"
  touch "$ROOTPATH"/.htaccess


  info "Setup placeholder install file"
  touch "$INSTALLFILE"

  if [ $REMOVEDEFAULTPLUGINS = "yes" ]; then
    
    info "Removing default wordpress plugins"
    rm -rf "$ROOTPATH"/wp-content/plugins/akismet/
    rm -f "$ROOTPATH"/wp-content/plugins/hello.php
    info "Default Wordpress Plugins Removed"

  fi

  ADDCUSTOMPLUGINS="yes"

  info "Finished running a new blank install"

fi

info "Fixing permissions"
chown -h 1001 "$ROOTPATH"/wp-config.php &>/dev/null
chown -h 1001 "$ROOTPATH"/wp-content &>/dev/null
chown -h 1001 "$ROOTPATH"/.alreadyinstalled &>/dev/null
touch "$ROOTPATH"/.htaccess &>/dev/null
chown -h 1001 "$ROOTPATH"/.htaccess &>/dev/null

info "Make sure wp-config paths and values are correct"
wp config set WP_DEBUG false --raw --path="$ROOTPATH"
wp config set WP_DEBUG_LOG false --raw --path="$ROOTPATH"
wp config set WP_PLUGIN_DIR "$WPCONTENTDIR"/plugins --path="$ROOTPATH"
wp config set FS_METHOD direct --path="$ROOTPATH"
wp config set WP_TEMP_DIR "$WPTEMPDIR" --path="$ROOTPATH"

info "Cleanup files for tidyness"
rm -rf "$ROOTPATH"/wp-config-sample.php
rm -rf "$ROOTPATH"/license.txt
rm -rf "$ROOTPATH"/readme.html

info "Remove maintenance file if it exists"
rm -rf "$ROOTPATH"/.maintenance

info "Make more changes to wp-config file (add custom function)"
yes | cp -rf /freshlabs.php "$ROOTPATH"/freshlabs.php

info "Delete old wpverinject function"
sed -i --follow-symlinks '/wpverinject();/d' "$ROOTPATH"/wp-config.php
sed -i --follow-symlinks -n '/$table_prefix =/{p; :a; N; /WP_DEBUG/!ba; s/.*\n//}; p' "$ROOTPATH"/wp-config.php

info "Delete previous require/freshlabs command"
sed -i --follow-symlinks "/freshlabs.php/d" "$ROOTPATH"/wp-config.php

info "Add new require/freshlabs command"
sed -i --follow-symlinks "\$arequire('"$ROOTPATH"/freshlabs.php');" "$ROOTPATH"/wp-config.php

# Consider importing SQL file if conditions met
if [ $MIGRATE_DB_TO_LOCAL = "yes" ] && [ -f "$ROOTPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql" ] && [ ! -f "$ROOTPATH/.migratedsql" ]; then

  # we will need to force recreate the wpconfig file
  info "Sinve we've migrated to a local environment we now need to fix our wp-config file"
  wp config set DB_NAME "${WORDPRESS_DATABASE_NAME}" --path="$ROOTPATH"
  wp config set DB_USER "${WORDPRESS_DATABASE_USER}" --path="$ROOTPATH"
  wp config set DB_PASSWORD "${WORDPRESS_DATABASE_PASSWORD}" --path="$ROOTPATH"
  wp config set DB_HOST "${MARIADB_HOST}:${MARIADB_PORT_NUMBER}" --path="$ROOTPATH"

  info "Found DB Import file, importing it now..."
  wp db import $ROOTPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql --path="$ROOTPATH"

  info "Setup placeholder db imported file (.migratedsql)"
  touch "$ROOTPATH/.migratedsql"

fi

if [ $ADDCUSTOMPLUGINS = "yes" ]; then
  # this is prime time to setup additional plugins (only on first install)
  info "Install custom or additional plugins ..."

  # Install Fresh Connect Plugin
  info "Installing Fresh Connect"
  wp plugin install fresh-connect --force --activate --path="$ROOTPATH"

  # Install Google Pagespeed
  info "Installing Google Pagespeed"
  wp plugin install google-pagespeed-insights --force --activate --path="$ROOTPATH"

  info "Install custom or additional plugins completed"
  # this is prime time to setup additional plugins (only on first install)

  # Grab FCK's 
  info "Now grabbing FCK"
  echo "Fresh Connect Key >>"
  wp option get fp_connection_keys --path="$ROOTPATH"
  echo "<< Fresh Connect Key"
  # Grab FCK's 
fi

info "Make sure both Wordpress and DB are up to date"
wp core update --version="$VERSIONONFILE" --path="$ROOTPATH"
wp core update-db --path="$ROOTPATH"

info "All done!"