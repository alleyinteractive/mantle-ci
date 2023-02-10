<?php
/**
 * Main integration file.
 *
 * @package wp-sqlite-integration
 * @since 1.0.0
 */

// Include the contents of the constants.php file.

// Temporary - This will be in wp-config.php once SQLite is merged in Core.
if ( ! defined( 'DATABASE_TYPE' ) ) {
	if ( defined( 'SQLITE_DB_DROPIN_VERSION' ) ) {
		define( 'DATABASE_TYPE', 'sqlite' );
	} else {
		define( 'DATABASE_TYPE', 'mysql' );
	}
}

/**
 * Notice:
 * Your scripts have the permission to create directories or files on your server.
 * If you write in your wp-config.php like below, we take these definitions.
 * define('DB_DIR', '/full_path_to_the_database_directory/');
 * define('DB_FILE', 'database_file_name');
 */

/**
 * FQDBDIR is a directory where the sqlite database file is placed.
 * If DB_DIR is defined, it is used as FQDBDIR.
 */
if ( ! defined( 'FQDBDIR' ) ) {
	if ( defined( 'DB_DIR' ) ) {
		define( 'FQDBDIR', trailingslashit( DB_DIR ) );
	} elseif ( defined( 'WP_CONTENT_DIR' ) ) {
		define( 'FQDBDIR', WP_CONTENT_DIR . '/database/' );
	} else {
		define( 'FQDBDIR', ABSPATH . 'wp-content/database/' );
	}
}

/**
 * FQDB is a database file name. If DB_FILE is defined, it is used
 * as FQDB.
 */
if ( ! defined( 'FQDB' ) ) {
	if ( defined( 'DB_FILE' ) ) {
		define( 'FQDB', FQDBDIR . DB_FILE );
	} else {
		define( 'FQDB', FQDBDIR . '.ht.sqlite' );
	}
}

// Bail early if DATABASE_TYPE is not defined as sqlite.
if ( ! defined( 'DATABASE_TYPE' ) || 'sqlite' !== DATABASE_TYPE ) {
	return;
}

if ( ! extension_loaded( 'pdo' ) ) {
	wp_die(
		new WP_Error(
			'pdo_not_loaded',
			sprintf(
				'<h1>%1$s</h1><p>%2$s</p>',
				'PHP PDO Extension is not loaded',
				'Your PHP installation appears to be missing the PDO extension which is required for this version of WordPress and the type of database you have specified.'
			)
		),
		'PHP PDO Extension is not loaded.'
	);
}

if ( ! extension_loaded( 'pdo_sqlite' ) ) {
	wp_die(
		new WP_Error(
			'pdo_driver_not_loaded',
			sprintf(
				'<h1>%1$s</h1><p>%2$s</p>',
				'PDO Driver for SQLite is missing',
				'Your PHP installation appears not to have the right PDO drivers loaded. These are required for this version of WordPress and the type of database you have specified.'
			)
		),
		'PDO Driver for SQLite is missing.'
	);
}

require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-pdo-user-defined-functions.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-pdo-engine.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-object-array.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-db.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-pdo-driver.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-create-query.php';
require_once ABSPATH . WPINC . '/sqlite/class-wp-sqlite-alter-query.php';
require_once ABSPATH . WPINC . '/sqlite/install-functions.php';

$GLOBALS['wpdb'] = new WP_SQLite_DB();
