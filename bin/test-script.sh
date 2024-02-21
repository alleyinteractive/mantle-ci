#!/bin/bash
set -e

# Test that the script ran correctly and properly installed WordPress.
echo ""
echo "Starting tests..."

if [ ! -d "$WP_CORE_DIR" ]; then
  echo "$WP_CORE_DIR does not exist."
  exit 1
fi

if [ ! -d "$WP_CORE_DIR/wp-admin" ]; then
  echo "$WP_CORE_DIR/wp-admin does not exist."
  exit 1
fi

if [ ! -f "$WP_CORE_DIR/wp-tests-config.php" ]; then
  echo "$WP_CORE_DIR/wp-tests-config.php does not exist."
  exit 1
fi

# Check the configuration.
CONFIG_FILE="$WP_CORE_DIR/wp-tests-config.php"

if ! grep -q "define( 'DB_NAME', 'wordpress_unit_tests' );" "$CONFIG_FILE"; then
  echo "DB_NAME is not set correctly."
  exit 1
fi

if ! grep -q "define( 'DB_USER', 'root' );" "$CONFIG_FILE"; then
  echo "DB_USER is not set correctly."
  exit 1
fi

if ! grep -q "define( 'DB_PASSWORD', 'root' );" "$CONFIG_FILE"; then
  echo "DB_PASSWORD is not set correctly."
  exit 1
fi

if ! grep -q "define( 'DB_HOST', 'localhost' );" "$CONFIG_FILE"; then
  echo "DB_HOST is not set correctly."
  exit 1
fi

if ! grep -q "defined( 'ABSPATH' ) || define( 'ABSPATH', __DIR__ . '/' );" "$CONFIG_FILE"; then
  echo "ABSPATH is not set correctly."
  exit 1
fi

if [ ! -d "$WP_CORE_DIR/wp-content/mu-plugins" ]; then
  echo "$WP_CORE_DIR/wp-content/mu-plugins (https://github.com/Automattic/vip-go-mu-plugins-built.git) does not exist."
  exit 1
fi

if [ ! -f "$WP_CORE_DIR/wp-content/object-cache.php" ]; then
  echo "$WP_CORE_DIR/wp-content/object-cache.php does not exist."
  exit 1
fi

if ! grep -q "require_once ABSPATH . 'wp-content/mu-plugins/000-pre-vip-config/requires.php';" "$CONFIG_FILE"; then
  echo "mu-plugins/000-pre-vip-config/requires.php is not loaded in wp-tests-config.php."
  exit 1
fi

if ! grep -q "require_once ABSPATH . 'wp-content/vip-config/vip-config.php';" "$CONFIG_FILE"; then
  echo "vip-config/vip-config.php is not loaded in wp-tests-config.php."
  exit 1
fi

# Check if the database was created if not using SQLite.
if [ -z "$WP_USE_SQLITE" ]; then
  if ! mysql -u root -proot -h 127.0.0.1 -e "use wordpress_unit_tests"; then
    echo "Database wordpress_unit_tests does not exist."
    exit 1
  fi
else
  # Check if the SQLite plugin is installed.
  if [ ! -f "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration/wp-includes/sqlite/db.php" ]; then
    echo "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration/wp-includes/sqlite/db.php does not exist."
    exit 1
  fi
fi

# If WP_INSTALL_CORE_TEST_SUITE is set to 1 then we should check if the core
# test suite is installed.
if [ "$WP_INSTALL_CORE_TEST_SUITE" == "1" ]; then
  if [ ! -d "/tmp/wordpress-tests-lib/includes" ]; then
    echo "/tmp/wordpress-tests-lib/includes does not exist."
    exit 1
  fi

  if [ ! -f "/tmp/wordpress-tests-lib/includes/functions.php" ]; then
    echo "/tmp/wordpress-tests-lib/includes/functions.php does not exist."
    exit 1
  fi
else
  echo "WP_INSTALL_CORE_TEST_SUITE is not set to 1."
fi

echo "WordPress installed successfully."
