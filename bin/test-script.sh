#!/bin/bash

# Test that the script ran correctly and properly installed WordPress.

if [ ! -d "$WP_CORE_DIR" ]; then
  echo "$WP_CORE_DIR does not exist."
  exit 1
fi

if [ ! -d "$WP_CORE_DIR/wp-admin" ]; then
  echo "$WP_CORE_DIR does not exist."
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

if ! grep -q "define( 'DB_PASSWORD', 'password' );" "$CONFIG_FILE"; then
  echo "DB_PASSWORD is not set correctly."
  exit 1
fi

if ! grep -q "define( 'DB_HOST', '127.0.0.1' );" "$CONFIG_FILE"; then
  echo "DB_HOST is not set correctly."
  exit 1
fi

if ! grep -q "defined( 'ABSPATH' ) || define( 'ABSPATH', '$WP_CORE_DIR/' );" "$CONFIG_FILE"; then
  echo "ABSPATH is not set correctly."
  exit 1
fi

echo "WordPress installed successfully."
