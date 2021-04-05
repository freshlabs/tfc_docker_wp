#!/bin/bash -e

# Require bitnami helper files and functions
. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

# Define some variables here
# Volatile Storage Path
VOLPATH="/opt/bitnami/tfc_wp";
# Permanent Storage Path
PERSPATH="/bitnami/tfc_wp";
# Install File Location
INSTALLFILE="$VOLPATH/.alreadyinstalled";
# Latest Version File Location
LATESTVERSION="$VOLPATH/.lastversioninstalled";
# WP Temporary Dir Location
WPTEMPDIR="$VOLPATH/tmp";
# WP Content Dir Location
WPCONTENTDIR="$VOLPATH/wp-content";
# Migration flag (overritten on an actual migration)
MIGRATIONFLAG="no";
# Add Custom plugins on a regular run?
ADDCUSTOMPLUGINS="no";
# Remove default plugins
REMOVEDEFAULTPLUGINS="yes"
# Stop defining variables


# Persistent/non-persistent is being removed. For now we just sync the two
# TODO: Clean up and have a single directory
info "Merging persistent and disposable directories."

info "Copying all files to live directory"
cp -rf "$PERSPATH" "$VOLPATH"

info "Deleting files from old directory"
rm -rf "$PERSPATH"/*

info "Finished merging persistent and disposable directories."

# Are we forcing a fresh start?
if [ $INSTALL_FORCE_CLEANUP = "yes" ]; then

    info "A reinstall flag was found, we are deleting the $INSTALLFILE file to force it ..."
    rm -rf "$INSTALLFILE"
    info "Removing .alreadyinstalled file completed."

fi

# Setup wp-cli cache to our permanent storage and export the variable
info "Set wp-cli cache dir at persistent storage"
export WP_CLI_CACHE_DIR="$VOLPATH"/.wp-cli/cache

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
  wp core download --version="$VERSIONONFILE" --locale=en_US --path="$VOLPATH" --force

# We need to identify if we are dealing with a new install (or cleanup) or if this is an existing build
if [ ! -f "$INSTALLFILE" ]; then

  info "Install file does not exist, so we are going for a full blank install"

  # Create the WP Config File
  info "Creating wp-config on Disposable Storage (placeholder)"
  wp config create --dbhost="${MARIADB_HOST}:${MARIADB_PORT_NUMBER}" --dbname="${WORDPRESS_DATABASE_NAME}" --dbprefix="${WORDPRESS_TABLE_PREFIX}" --dbcharset=utf8 --dbuser="${WORDPRESS_DATABASE_USER}" --dbpass="${WORDPRESS_DATABASE_PASSWORD}" --locale=en_US --skip-check --path="$VOLPATH" --force

  # Set some flags on wp-config file
  info "Making aditional adjustments to wp-config.php file"
  wp config set WP_DEBUG false --raw --path="$VOLPATH"
  wp config set WP_DEBUG_LOG false --raw --path="$VOLPATH"
  wp config set WP_PLUGIN_DIR "$WPCONTENTDIR"/plugins --path="$VOLPATH"
  wp config set FS_METHOD direct --path="$VOLPATH"
  wp config set WP_TEMP_DIR "$WPTEMPDIR" --path="$VOLPATH"

  # Make some changes to wp-config file
  info "Using SED to adjust our wp-config.php file with some additional settings"
  sed -i "s/dirname( __FILE__ )/'"${VOLPATH//'/'/'\/'}"'/g" "$VOLPATH"/wp-config.php

  # Append some additional data to wp-config file
  info "Append some additional functions to wp-config.php file"
  sed -i "\$aif ( \!defined( 'WP_CLI' ) ) \{\n\/\/  Disable pingback.ping xmlrpc method to prevent WordPress from participating in DDoS attacks\n\/\/  More info at: https://wiki.bitnami.com/Applications/Bitnami_WordPress#XMLRPC_and_Pingback\n\n// remove x-pingback HTTP header\nadd_filter('wp_headers', function(\$headers) \{\n            unset(\$headers['X-Pingback']);\n            return \$headers;\n           \});\n// disable pingbacks\nadd_filter( 'xmlrpc_methods', function( \$methods ) \{\n             unset( \$methods['pingback.ping'] );\n             return \$methods;\n           \});\n}" "$VOLPATH"/wp-config.php

  # Run WP Install Procedure
  info "Let us run the install now"
  #wp core install --url=localhost --title="aaaa" --admin_user="momon" --admin_password="1234" --admin_email="redstormj@gmail.com" --path="/opt/bitnami/tfc_wp" --skip-email
  wp core install --url="${WORDPRESS_BLOG_URL}" --title="${WORDPRESS_BLOG_NAME}" --admin_user="${WORDPRESS_USERNAME}" --admin_password="${WORDPRESS_PASSWORD}" --admin_email="${WORDPRESS_EMAIL}" --path="$VOLPATH" --skip-email

  info "Creating placeholder files"
  touch "$VOLPATH"/.htaccess


  info "Setup placeholder install file"
  touch "$INSTALLFILE"

  if [ $REMOVEDEFAULTPLUGINS = "yes" ]; then
    
    info "Removing default wordpress plugins"
    rm -rf "$VOLPATH"/wp-content/plugins/akismet/
    rm -f "$VOLPATH"/wp-content/plugins/hello.php
    info "Default Wordpress Plugins Removed"

  fi

  ADDCUSTOMPLUGINS="yes"

  info "Finished running a new blank install"

fi

info "Fixing permissions"
chown -h 1001 "$VOLPATH"/wp-config.php
chown -h 1001 "$VOLPATH"/wp-content

info "Cleanup files for tidyness"
rm -rf "$VOLPATH"/wp-config-sample.php
rm -rf "$VOLPATH"/license.txt
rm -rf "$VOLPATH"/readme.html

info "Make more changes to wp-config file (add custom function)"
yes | cp -rf /freshlabs.php "$VOLPATH"/freshlabs.php

info "Delete old wpverinject function"
sed -i --follow-symlinks '/wpverinject();/d' "$VOLPATH"/wp-config.php
sed -i --follow-symlinks -n '/$table_prefix =/{p; :a; N; /WP_DEBUG/!ba; s/.*\n//}; p' "$VOLPATH"/wp-config.php

info "Delete previous require/freshlabs command"
sed -i --follow-symlinks "/freshlabs.php/d" "$VOLPATH"/wp-config.php

info "Add new require/freshlabs command"
sed -i --follow-symlinks "\$arequire('"$VOLPATH"/freshlabs.php');" "$VOLPATH"/wp-config.php

# Consider importing SQL file if conditions met
if [ $MIGRATE_DB_TO_LOCAL = "yes" ] && [ -f "$VOLPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql" ] && [ ! -f "$VOLPATH/.migratedsql" ]; then

  # we will need to force recreate the wpconfig file
  info "Sinve we've migrated to a local environment we now need to fix our wp-config file"
  wp config set DB_NAME "${WORDPRESS_DATABASE_NAME}" --path="$VOLPATH"
  wp config set DB_USER "${WORDPRESS_DATABASE_USER}" --path="$VOLPATH"
  wp config set DB_PASSWORD "${WORDPRESS_DATABASE_PASSWORD}" --path="$VOLPATH"
  wp config set DB_HOST "${MARIADB_HOST}:${MARIADB_PORT_NUMBER}" --path="$VOLPATH"

  info "Found DB Import file, importing it now..."
  wp db import $VOLPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql --path="$VOLPATH"

  info "Setup placeholder db imported file (.migratedsql)"
  touch "$VOLPATH/.migratedsql"

fi

if [ $ADDCUSTOMPLUGINS = "yes" ]; then
  # this is prime time to setup additional plugins (only on first install)
  info "Install custom or additional plugins ..."

  # Install Fresh Connect Plugin
  info "Installing Fresh Connect"
  wp plugin install fresh-connect --force --activate --path="$VOLPATH"

  # Install Google Pagespeed
  info "Installing Google Pagespeed"
  wp plugin install google-pagespeed-insights --force --activate --path="$VOLPATH"

  info "Install custom or additional plugins completed"
  # this is prime time to setup additional plugins (only on first install)

  # Grab FCK's 
  info "Now grabbing FCK"
  echo "Fresh Connect Key >>"
  wp option get fp_connection_keys --path="$VOLPATH"
  echo "<< Fresh Connect Key"
  # Grab FCK's 
fi

info "Make sure both Wordpress and DB are up to date"
wp core update --version="$VERSIONONFILE" --path="$VOLPATH"
wp core update-db --path="$VOLPATH"

info "All done!"