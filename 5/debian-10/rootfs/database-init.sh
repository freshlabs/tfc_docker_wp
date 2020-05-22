#!/bin/bash

# Load up helper functions
. /opt/bitnami/base/functions
. /opt/bitnami/base/helpers

MYSQLBASECMD="mysql -h $MARIADB_HOST -P $MARIADB_PORT_NUMBER -u $MARIADB_ROOT_USER -p$MARIADB_ROOT_PASSWORD";

# Are we forcing a cleanup?
if [ $INSTALL_FORCE_CLEANUP = "yes" ]; then

    info "A cleanup flag was found, we are deleting the database '$WORDPRESS_DATABASE_NAME' ..."
    mysql_cmd=( $MYSQLBASECMD -e 'DROP DATABASE IF EXISTS `'$WORDPRESS_DATABASE_NAME'`' )
    "${mysql_cmd[@]}"
    info "Permanent database cleanup completed."

    info "We are now deleting the database user '$WORDPRESS_DATABASE_USER' ..."
    mysql_cmd=( $MYSQLBASECMD -e 'DROP USER IF EXISTS `'$WORDPRESS_DATABASE_USER'`' )
    "${mysql_cmd[@]}"
    info "Permanent database user cleanup completed."

fi
# Are we forcing a cleanup?

# Setting up Database ...
info "Creating Database for this install '$WORDPRESS_DATABASE_NAME' ..."
mysql_cmd=( $MYSQLBASECMD -e 'CREATE DATABASE IF NOT EXISTS `'$WORDPRESS_DATABASE_NAME'`' )
"${mysql_cmd[@]}"
info "Database creation completed"
# Setting up Database Finished

# Setting up database USR / PWD ...
info "Creating Database User for this database '$WORDPRESS_DATABASE_USER' ..."
mysql_cmd=( $MYSQLBASECMD -e 'CREATE USER IF NOT EXISTS `'$WORDPRESS_DATABASE_USER'`@`%` IDENTIFIED BY "'$WORDPRESS_DATABASE_PASSWORD'"' )
"${mysql_cmd[@]}"
info "Database User creation completed"
# Setting up database USR / PWD Finished

# Grant new USR DB Permissions ...
info "Assigning DB Permissions to new USR '$WORDPRESS_DATABASE_USER' to '$WORDPRESS_DATABASE_NAME' ..."
mysql_cmd=( $MYSQLBASECMD -e 'GRANT ALL PRIVILEGES ON `'$WORDPRESS_DATABASE_NAME'`.* TO `'$WORDPRESS_DATABASE_USER'`@`%`' )
"${mysql_cmd[@]}"
info "Assigning DB Permissions to new USR completed"
# Grant new USR DB Permissions Finished