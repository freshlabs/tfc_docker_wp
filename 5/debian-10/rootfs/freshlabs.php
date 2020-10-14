<?php

    if ( defined( 'WP_CLI' ) ) {
        $_SERVER['HTTP_HOST'] = '127.0.0.1';
    }

    define('WP_SITEURL','https://' . $_SERVER['HTTP_HOST'] . '/');
    define('WP_HOME','https://' . $_SERVER['HTTP_HOST'] . '/');

    // This is a simple function that attempts to keep the current installed wp version available on a helper file
    function freshlabscode() {

        if (!file_exists('/bitnami/tfc_wp/.lastversioninstalled')) {
            file_put_contents('/bitnami/tfc_wp/.lastversioninstalled', '0.0.0'); // Dummy value
        }

        // Set placeholders
        $wp_v_installed = shell_exec('wp core version --path=/opt/bitnami/tfc_wp');
        $wp_v_onfile    = file_get_contents('/bitnami/tfc_wp/.lastversioninstalled');

        if($wp_v_installed != $wp_v_onfile) {
            file_put_contents('/bitnami/tfc_wp/.lastversioninstalled', $wp_v_installed);
        }

        if (file_exists('/opt/bitnami/tfc_wp/wordfence-waf.php') && is_link('/opt/bitnami/tfc_wp/wordfence-waf.php') == false) {
            shell_exec('mv /opt/bitnami/tfc_wp/wordfence-waf.php /bitnami/tfc_wp/wordfence-waf.php');
            symlink('/bitnami/tfc_wp/wordfence-waf.php', '/opt/bitnami/tfc_wp/wordfence-waf.php');
        }

    }

    freshlabscode();