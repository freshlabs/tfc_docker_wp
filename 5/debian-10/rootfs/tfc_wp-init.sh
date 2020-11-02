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
INSTALLFILE="$PERSPATH/.alreadyinstalled";
# Latest Version File Location
LATESTVERSION="$PERSPATH/.lastversioninstalled";
# WP Temporary Dir Location
WPTEMPDIR="$VOLPATH/tmp";
# WP Content Dir Location
WPCONTENTDIR="$PERSPATH/wp-content";
# Migration flag (overritten on an actual migration)
MIGRATIONFLAG="no";
# Add Custom plugins on a regular run?
ADDCUSTOMPLUGINS="no";
# Remove default plugins
REMOVEDEFAULTPLUGINS="yes"
# Stop defining variables

# This placeholder function should run only when the container is executed as root so we can migrate to non-root environment
# when we no longer need to migrate older bitnami deployments, this can be removed as well as the 1001 user creation
if [ -d "/bitnami/wordpress" ]; then

  info "Looks like a previous wordpress install existed here, lets bring that data over to our new setup."

  sudo mkdir -p "$PERSPATH"
  yes | sudo cp -rf /bitnami/wordpress/* "$PERSPATH"

  info "Change bitnami dir owner and permissions to non-root"
  sudo chown -R 1001:1001 /bitnami
  sudo chmod 775 /bitnami

  info "We should now rename that old wordpress install so we don't re-import it again in the future"
  mv /bitnami/wordpress /bitnami/bitnami_wp_backup

  MIGRATIONFLAG="yes";

fi
# This placeholder function should run only when the container is executed as root so we can migrate to non-root environment

# Are we forcing a fresh start?
if [ $INSTALL_FORCE_CLEANUP = "yes" ]; then

    info "A reinstall flag was found, we are deleting the $INSTALLFILE file to force it ..."
    rm -rf "$INSTALLFILE"
    info "Removing .alreadyinstalled file completed."

fi

# Setup wp-cli cache to our permanent storage and export the variable
info "Set wp-cli cache dir at persistent storage"
export WP_CLI_CACHE_DIR="$PERSPATH"/.wp-cli/cache

# Download WP Core files to disposable storage
if [ ! -f "$LATESTVERSION" ]; then

  VERSIONONFILE="5.5.3"

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

  info "Install file does not exists, so we are going for a full blank install"

  # Create the WP Confir File
  info "Creating wp-config on Disposable Storage"

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
  wp core install --url=localhost --title="${WORDPRESS_BLOG_NAME}" --admin_user="${WORDPRESS_USERNAME}" --admin_password="${WORDPRESS_PASSWORD}" --admin_email="${WORDPRESS_EMAIL}" --path="$VOLPATH" --skip-email

  info "Creating placeholder files"
  touch "$VOLPATH"/.htaccess

  info "Our migration flag value is currently reported as: $MIGRATIONFLAG"

  # Are we forcing a migration start?
  if [ $MIGRATIONFLAG = "no" ]; then

    info "Cleanup the placeholder files before moving them"
    rm -rf "$PERSPATH"/.htaccess "$PERSPATH"/wp-config.php "$WPCONTENTDIR"

    info "Moving some files from Disposable Storage to Persistent Storage"
    mv -f "$VOLPATH"/.htaccess "$PERSPATH"/.htaccess
    mv -f "$VOLPATH"/wp-config.php "$PERSPATH"/wp-config.php
    mv -f "$VOLPATH"/wp-content "$WPCONTENTDIR"

  elif [ $MIGRATIONFLAG = "yes" ]; then

    info "Remove virgin install default files from volatile storage"
    rm -rf "$VOLPATH"/.htaccess
    rm -rf "$VOLPATH"/wp-content

    info "Move our new wp-config.php file to perm storage"
    mv -f "$VOLPATH"/wp-config.php "$PERSPATH"/wp-config.php

  fi

  info "Setup placeholder install file"
  touch "$INSTALLFILE"

  if [ $REMOVEDEFAULTPLUGINS = "yes" ]; then
    
    info "Removing default wordpress plugins"
    rm -rf "$PERSPATH"/wp-content/plugins/akismet/
    rm -f "$PERSPATH"/wp-content/plugins/hello.php
    info "Default Wordpress Plugins Removed"

  fi

  ADDCUSTOMPLUGINS="yes"

fi

info "This appears to be an existing install, so we are just recovering the existing website"

# We need to evaluate if some files are sym links or files / directories and delete them accordingly
if [ -f "$VOLPATH/.htaccess" ]; then
  info "The .htaccess on the vol directory should not exists at this point, we are deleting it."
  rm -rf "$VOLPATH"/.htaccess
fi

if [ -f "$VOLPATH/wp-config.php" ]; then
  info "The wp-config.php on the vol directory should not exists at this point, we are deleting it."
  rm -rf "$VOLPATH"/wp-config.php
fi

if [ -d "$VOLPATH/wp-content" ]; then
  info "The wp-content on the vol directory should not exists at this point, we are deleting it."
  rm -rf "$VOLPATH"/wp-content/
fi

# We need to check for wordfence and persist its required root files
if [ -f "$VOLPATH/wordfence-waf.php" ]; then
  info "The wordfence-waf.php on the vol directory should not exists at this point, we are persisting it and creating a symbolic link instead."
  mv "$VOLPATH"/wordfence-waf.php "$PERSPATH"/wordfence-waf.php
  ln -nsf "$PERSPATH"/wordfence-waf.php "$VOLPATH"/wordfence-waf.php
fi

# Everything from this point forward is to be executed regardless of an install or upgrade
info "Create Symbolic links to Persistent Storage"
ln -nsf "$PERSPATH"/.htaccess "$VOLPATH"/.htaccess
ln -nsf "$PERSPATH"/wp-config.php "$VOLPATH"/wp-config.php
ln -nsf "$WPCONTENTDIR" "$VOLPATH"/wp-content

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
if [ $MIGRATE_DB_TO_LOCAL = "yes" ] && [ -f "$PERSPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql" ] && [ ! -f "$PERSPATH/.migratedsql" ]; then

  # we will need to force recreate the wpconfig file
  info "Sinve we've migrated to a local environment we now need to fix our wp-config file"
  wp config set DB_NAME "${WORDPRESS_DATABASE_NAME}" --path="$VOLPATH"
  wp config set DB_USER "${WORDPRESS_DATABASE_USER}" --path="$VOLPATH"
  wp config set DB_PASSWORD "${WORDPRESS_DATABASE_PASSWORD}" --path="$VOLPATH"
  wp config set DB_HOST "${MARIADB_HOST}:${MARIADB_PORT_NUMBER}" --path="$VOLPATH"

  info "Found DB Import file, importing it now..."
  wp db import $PERSPATH/$MIGRATE_WORDPRESS_DATABASE_NAME-migrate.sql --path="$VOLPATH"

  info "Setup placeholder db imported file (.migratedsql)"
  touch "$PERSPATH/.migratedsql"

fi
# Consider importing SQL file if conditions met

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

info "We done dawg... let's get the party started >.<"