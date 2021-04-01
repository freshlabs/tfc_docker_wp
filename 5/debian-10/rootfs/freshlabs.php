<?php

if (defined('WP_CLI')) {
    $_SERVER['HTTP_HOST'] = '127.0.0.1';
}
define('WP_SITEURL', 'https://'.$_SERVER['HTTP_HOST'].'/');
define('WP_HOME', 'https://'.$_SERVER['HTTP_HOST'].'/');

/**
 * Keeps track of the current installed version
 * and fixes issues with WordFence plugin putting files in the root
 */
function runFreshCloudCode()
{
    if (!file_exists('/bitnami/tfc_wp/.lastversioninstalled')) {
        file_put_contents('/bitnami/tfc_wp/.lastversioninstalled', '0.0.0'); // Dummy value
    }

    // Set placeholders
    $wp_v_installed = get_bloginfo('version');
    $wp_v_onfile = file_get_contents('/bitnami/tfc_wp/.lastversioninstalled');

    if ($wp_v_installed != $wp_v_onfile) {
        file_put_contents('/bitnami/tfc_wp/.lastversioninstalled', $wp_v_installed);
    }

    if (file_exists('/opt/bitnami/tfc_wp/wordfence-waf.php') && is_link('/opt/bitnami/tfc_wp/wordfence-waf.php') == false) {
        shell_exec('mv /opt/bitnami/tfc_wp/wordfence-waf.php /bitnami/tfc_wp/wordfence-waf.php');
        symlink('/bitnami/tfc_wp/wordfence-waf.php', '/opt/bitnami/tfc_wp/wordfence-waf.php');
    }

}

if (function_exists('add_action')) {
    add_action('activated_plugin', 'runFreshCloudCode');
    add_action('upgrader_process_complete', 'runFreshCloudCode');
}