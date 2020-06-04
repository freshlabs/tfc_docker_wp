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
info "Downloading WP to Disposable Storage"
wp core download --locale=en_US --path="$VOLPATH" --force

# We need to identify if we are dealing with a new install (or cleanup) or if this is an existing build
if [ ! -f "$INSTALLFILE" ]; then

  # Create the WP Confir File
  info "Creating wp-config on Disposable Storage"
  wp config create --dbhost="${MARIADB_HOST}" --dbname="${WORDPRESS_DATABASE_NAME}" --dbprefix="${WORDPRESS_TABLE_PREFIX}" --dbcharset=utf8 --dbuser="${WORDPRESS_DATABASE_USER}" --dbpass="${WORDPRESS_DATABASE_PASSWORD}" --locale=en_US --skip-check --path="$VOLPATH" --force --extra-php <<PHP
  if ( defined( 'WP_CLI' ) ) {
    \$_SERVER['HTTP_HOST'] = '127.0.0.1';
  }
  define('WP_SITEURL','https://' . \$_SERVER['HTTP_HOST'] . '/');
  define('WP_HOME','https://' . \$_SERVER['HTTP_HOST'] . '/');
  // This is a simple function that attempts to keep the current installed wp version available on a helper file
  function wpverinject() {
    if (!file_exists('$LATESTVERSION')) {   
      file_put_contents('$LATESTVERSION', '0.0.0'); // Dummy value
      file_put_contents('$LATESTVERSION'.'.md5', '1.1.1'); // Dummy value
    }
    // Compare MD5
    if(md5_file('$LATESTVERSION') != file_get_contents('$LATESTVERSION'.'.md5')) {
      file_put_contents('$LATESTVERSION', shell_exec('wp core version --path=$VOLPATH'));
      \$md5file = md5_file('$LATESTVERSION');
      file_put_contents('$LATESTVERSION'.'.md5', \$md5file);
    }
  }
PHP

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

  # Append some additional data to wp-config file
  info "Append the custom wp version file generator"
  sed -i "\$awpverinject();" "$VOLPATH"/wp-config.php

  # Run WP Install Procedure
  info "Let us run the install now"
  wp core install --url=localhost --title="Sample Webiste by Jose Lopez" --admin_user=supervisor --admin_password=strongpassword --admin_email=jose@freshlabs.team --path="$VOLPATH" --skip-email

  info "Creating placeholder files"
  touch "$VOLPATH"/.htaccess

  # Are we forcing a fresh start?
  if [ $MIGRATIONFLAG = "no" ] then

    info "Cleanup the placeholder files before moving them"
    rm -rf "$PERSPATH"/.htaccess "$PERSPATH"/wp-config.php "$WPCONTENTDIR"

    info "Moving some files from Disposable Storage to Persistent Storage"
    mv -f "$VOLPATH"/.htaccess "$PERSPATH"/.htaccess
    mv -f "$VOLPATH"/wp-config.php "$PERSPATH"/wp-config.php
    mv -f "$VOLPATH"/wp-content "$WPCONTENTDIR"

  elif [ $MIGRATIONFLAG = "yes" ] then

    info "Remove virgin install default files from volatile storage"
    rm -rf "$VOLPATH"/.htaccess
    rm -rf "$VOLPATH"/wp-config.php
    rm -rf "$VOLPATH"/wp-content

  fi

  info "Setup placeholder install file"
  touch "$INSTALLFILE"

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

info "We done dawg... let's get the party started >.<"