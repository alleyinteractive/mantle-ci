<?php
/**
 *  __  __             _   _        ____ ___
 * |  \/  | __ _ _ __ | |_| | ___  / ___|_ _|
 * | |\/| |/ _` | '_ \| __| |/ _ \| |    | |
 * | |  | | (_| | | | | |_| |  __/| |___ | |
 * |_|  |_|\__,_|_| |_|\__|_|\___| \____|___|
 *
 * mantle-ci WordPress Testing Configuration File
 *
 * This file is used by install-wp-tests.sh as the base wp-tests-config.php for
 * WordPress unit tests.
 *
 * @link https://mantle.alley.com/docs/testing/installation-manager
 */

/* Path to the WordPress codebase you'd like to test. Add a forward slash in the end. */
defined( 'ABSPATH' ) || define( 'ABSPATH', __DIR__ . '/' );

/*
 * Path to the theme to test with.
 *
 * This is an environment variable to ensure it is properly passed to the
 * installation subprocess. The constant WP_DEFAULT_THEME is used as a default
 * but is not encouraged.
 *
 * @link https://mantle.alley.com/docs/testing/installation-manager#changing-the-active-theme
 */
if ( ! getenv( 'WP_DEFAULT_THEME' ) ) {
  putenv( 'WP_DEFAULT_THEME=' . ( defined( 'WP_DEFAULT_THEME' ) ? WP_DEFAULT_THEME : 'default' ) );
}

/*
 * Test with multisite enabled.
 */
// define( 'WP_TESTS_MULTISITE', true );

// Test with WordPress debug mode (default).
define( 'WP_DEBUG', true );

// ** Database settings ** //

/*
 * This configuration file will be used by the copy of WordPress being tested.
 * wordpress/wp-config.php will be ignored.
 *
 * WARNING WARNING WARNING!
 * These tests will DROP ALL TABLES in the database with the prefix named below.
 * DO NOT use a production database or one that is shared with something else.
 */

define( 'DB_NAME', 'youremptytestdbnamehere' );
define( 'DB_USER', 'yourusernamehere' );
define( 'DB_PASSWORD', 'yourpasswordhere' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

$table_prefix = 'wptests_';   // Only numbers, letters, and underscores please!

defined( 'WP_TESTS_DOMAIN' ) || define( 'WP_TESTS_DOMAIN', 'example.org' );
defined( 'WP_TESTS_EMAIL' ) || define( 'WP_TESTS_EMAIL', 'admin@example.org' );
defined( 'WP_TESTS_TITLE' ) || define( 'WP_TESTS_TITLE', 'Test Blog' );

defined( 'WP_PHP_BINARY' ) || define( 'WP_PHP_BINARY', 'php' );

defined( 'WPLANG' ) || define( 'WPLANG', '' );
