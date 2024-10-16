#!/usr/bin/env bash
set -e

# Install WordPress Tests for Development
#
# Primarily geared for development with Mantle framerwork/Mantle Testkit but also
# supports installing the core WordPress test suite as well. Mirrors the
# WordPress/wp-cli install-wp-tests.sh script with a few modifications:
#
# 1. By default it will not install the core test suite. This means that we will
#    only install WordPress to `WP_CORE_DIR` but will not install the test suite
#    to `WP_TESTS_DIR`. This can be configured by setting `WP_INSTALL_CORE_TEST_SUITE` to true.
# 2. It will attempt to cache remote data requests for 4 hours. This can be
#    configured by the `CACHEDIR` environment variable for the location of the cache
#    directory. It can also be disabled by setting `CACHEDIR` to false.
# 3. The script can optionally install Automattic's vip-mu-plugins-built. Defaults to false.
# 4. The script can optionally install the `object-cache.php` file for Memcached or Redis. This can be configured by passing
#    the `<install-object-cache>` argument to the command. Valid values are `true` (memcached), memcached, or redis.
#
# Usage:
#
# 	install-wp-tests.sh <db-name> <db-user> <db-pass> <db-host> <wp-version> <skip-database-creation> <install-vip-mu-plugins> <install-object-cache>
#
# Arguments (all are optional but must be in order and cannot be skipped):
#
# 	1. Database Name: defaults to "wordpress_unit_tests"
# 	2. Database User: defaults to "root"
# 	3. Database Password: defaults to ""
# 	4. Database Host: defaults to "localhost"
# 	5. WordPress Version: defaults to "latest"
# 	6. Skip Database Creation: defaults to false
# 	7. Install WordPress VIP's `Automattic/vip-go-mu-plugins-built` project to the `mu-plugins` directory: defaults to false
# 	8. Install Object Cache: defaults to false (valid values are `true` (memcached), memcached, or redis)
#
# Environment Variables:
#
# 	CACHEDIR: The location of the cache directory.
# 		Defaults to /tmp.
# 	WP_CORE_DIR: The location of the WordPress core directory.
# 		Defaults to /tmp/wordpress.
# 	WP_TESTS_DIR: The location of the WordPress core test suite directory.
# 		Defaults to /tmp/wordpress-tests-lib. Not used if WP_INSTALL_CORE_TEST_SUITE is not true.
# 	WP_MULTISITE: Whether or not to install WordPress as multisite.
# 		Defaults to false.
# 	WP_INSTALL_CORE_TEST_SUITE: Whether or not to install the WordPress core test suite.
# 		Defaults to false.
# 	WP_TESTS_TAG: The tag of the WordPress core test suite to install.
# 		Defaults to "trunk".
# 	WP_USE_SQLITE: Whether or not to use SQLite for the database.
# 		Defaults to false.
# 	INSTALL_WP_TEST_DEBUG: Whether or not to dump all variables for debugging.
# 		Defaults to false.
# 	INSTALL_OBJECT_CACHE: Whether or not to install the object-cache.php file.
# 		Defaults to false.
#
# Example:
#
# 	install-wp-tests.sh wordpress_unit_tests root '' localhost latest false false false

# Convenient functions for printing colored text
function green {
  # green text to stdout
  echo "$@" | sed $'s,.*,\e[32m&\e[m,' | xargs -0 printf
}

function yellow {
  # yellow text to stderr
  echo "$@" | sed $'s,.*,\e[33m&\e[m,' | >&2 xargs -0 printf
}

function red {
  # red text to stderr
  echo "$@" | sed $'s,.*,\e[31m&\e[m,' | >&2 xargs -0 printf
}

# Handle true/false values
function boolean() {
  if [[ "$1" =~ ^(true|yes|on|1)$ ]]; then
    echo "true"
  elif [[ "$1" =~ ^(false|no|off|0)$ ]]; then
    echo "false"
  else
    red "Error: Invalid boolean value for '$2': '$1'. Must be 'true' or 'false'."
    exit 1
  fi
}

# Handle string values
function string() {
  if [[ "$1" =~ ^(true|yes|on|1)$ ]]; then
    echo "true"
  elif [[ "$1" =~ ^(false|no|off|0)$ ]]; then
    echo "false"
  else
    echo "$1"
  fi
}

# Arguments passed to the script directly with defaults.
DB_NAME="${1:-wordpress_unit_tests}"
DB_USER="${2:-root}"
DB_PASS="${3:-}"
DB_HOST="${4:-localhost}"
WP_VERSION="${5:-latest}"
SKIP_DB_CREATE=$(boolean "${6:-false}" "SKIP_DB_CREATE")
INSTALL_VIP_MU_PLUGINS=$(boolean "${7:-false}" "INSTALL_VIP_MU_PLUGINS")
INSTALL_OBJECT_CACHE=$(string "${8:-false}" "INSTALL_OBJECT_CACHE")

# Environment variables with defaults.
CACHEDIR=${CACHEDIR:-/tmp}
CACHEDIR=$(echo "$CACHEDIR" | sed -e "s/\/$//") # Remove trailing slash if present.
WP_CORE_DIR=${WP_CORE_DIR:-"${CACHEDIR}/wordpress"}
WP_TESTS_DIR=${WP_TESTS_DIR:-/tmp/wordpress-tests-lib} # Only used with core test suite.
WP_MULTISITE=${WP_MULTISITE:-0}
WP_INSTALL_CORE_TEST_SUITE=$(boolean "${WP_INSTALL_CORE_TEST_SUITE:-false}" "WP_INSTALL_CORE_TEST_SUITE")
WP_USE_SQLITE=$(boolean "${WP_USE_SQLITE:-false}" "WP_USE_SQLITE")
INSTALL_WP_TEST_DEBUG=$(boolean "${INSTALL_WP_TEST_DEBUG:-false}" "INSTALL_WP_TEST_DEBUG")
INSTALL_VIP_CONFIG=$(boolean "${INSTALL_VIP_CONFIG:-${INSTALL_VIP_MU_PLUGINS}}" "INSTALL_VIP_CONFIG") # Inherit the default value from INSTALL_VIP_MU_PLUGINS.
echo "Debug Mode: $INSTALL_WP_TEST_DEBUG"

# Allow the script to dump all variables for debugging.
if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
  set -x

  green "Dumping all variables for debugging:"

  echo "WP_VERSION: ${WP_VERSION}"
  echo "WP_CORE_DIR: ${WP_CORE_DIR}"
  echo "CACHEDIR: ${CACHEDIR}"
  echo "WP_TESTS_DIR: ${WP_TESTS_DIR}"
  echo "WP_MULTISITE: ${WP_MULTISITE}"
  echo "DB_NAME: ${DB_NAME}"
  echo "DB_USER: ${DB_USER}"
  echo "DB_PASS: ${DB_PASS}"
  echo "DB_HOST: ${DB_HOST}"
  echo "SKIP_DB_CREATE: ${SKIP_DB_CREATE}"
  echo "INSTALL_VIP_MU_PLUGINS: ${INSTALL_VIP_MU_PLUGINS}"
  echo "INSTALL_VIP_CONFIG: ${INSTALL_VIP_CONFIG}"
  echo "INSTALL_OBJECT_CACHE: ${INSTALL_OBJECT_CACHE}"
  echo "WP_INSTALL_CORE_TEST_SUITE: ${WP_INSTALL_CORE_TEST_SUITE}"
  echo "WP_USE_SQLITE: ${WP_USE_SQLITE}"
fi

# Create the cache directory if it doesn't exist.
mkdir -p "$CACHEDIR"

# List the contents of the cache directory if debugging.
if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
  ls -al "$CACHEDIR"
fi

download() {
  # Check if the file has been downloaded in the last 72 hours.
  # If it has been, use it instead of downloading it again.
  if [[ -f $2 ]]; then
    if test "$(find "$2" -mtime -3)"; then
      yellow "Using cached $2"

      return
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    curl -f -s -L "$1" > "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -nv --location -O "$2" "$1"
  else
    red "Could not find curl or wget"
    exit 1
  fi

  # Exit if the last command failed.
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "Downloading $1 failed"
    exit 1
  fi
}

# Determine the WordPress core test tag to install and the latest version of
# WordPress that can be installed.
if [[ $WP_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
  WP_TESTS_TAG="$WP_VERSION"
elif [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
  if [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0] ]]; then
    # version x.x.0 means the first release of the major version, so strip off the .0 and download version x.x
    WP_TESTS_TAG="${WP_VERSION%??}"
  else
    WP_TESTS_TAG="$WP_VERSION"
  fi
elif [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
  WP_TESTS_TAG="trunk"
else
  # http serves a single offer, whereas https serves multiple. we only want one
  download http://api.wordpress.org/core/version-check/1.7/ "$CACHEDIR/wp-latest.json"

  LATEST_VERSION=$(grep -o '"version":"[^"]*' "$CACHEDIR/wp-latest.json" | sed 's/"version":"//')

  if [[ -z "$LATEST_VERSION" ]]; then
    echo "Latest WordPress version could not be found"
    exit 1
  fi
  WP_TESTS_TAG="$LATEST_VERSION"
fi

install_wp() {
  if [ -d "$WP_CORE_DIR" ]; then
    if [ -f "$WP_CORE_DIR/wp-load.php" ]; then
      echo "WordPress already installed at [$WP_CORE_DIR]"
      return
    fi
  fi

  green "Installing WordPress at [$WP_CORE_DIR]"

  mkdir -p "$WP_CORE_DIR"

  if [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
    mkdir -p "$CACHEDIR/wordpress-nightly"
    download "https://wordpress.org/nightly-builds/wordpress-latest.zip"  "$CACHEDIR/wordpress-nightly/wordpress-nightly.zip"
    unzip -q "$CACHEDIR/wordpress-nightly/wordpress-nightly.zip" -d "$CACHEDIR/wordpress-nightly/"
    mv "$CACHEDIR/wordpress-nightly/wordpress/"* "$WP_CORE_DIR"
  else
    if [ "$WP_VERSION" == 'latest' ]; then
      ARCHIVE_NAME='latest'
    elif [[ $WP_VERSION =~ [0-9]+\.[0-9]+ ]]; then
      # https serves multiple offers, whereas http serves single.
      download "https://api.wordpress.org/core/version-check/1.7/" "$CACHEDIR/wp-latest.json"
      if [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0] ]]; then
        # version x.x.0 means the first release of the major version, so strip off the .0 and download version x.x
        LATEST_VERSION=${WP_VERSION%??}
      else
        # otherwise, scan the releases and get the most up to date minor version of the major release
        # shellcheck disable=SC2001
        VERSION_ESCAPED=$(echo "$WP_VERSION" | sed 's/\./\\\\./g')
        LATEST_VERSION=$(grep -o '"version":"'"$VERSION_ESCAPED"'[^"]*' "$CACHEDIR/wp-latest.json" | sed 's/"version":"//' | head -1)
      fi
      if [[ -z "$LATEST_VERSION" ]]; then
        ARCHIVE_NAME="wordpress-$WP_VERSION"
      else
        ARCHIVE_NAME="wordpress-$LATEST_VERSION"
      fi
    else
      ARCHIVE_NAME="wordpress-$WP_VERSION"
    fi
    download "https://wordpress.org/${ARCHIVE_NAME}.tar.gz" "${CACHEDIR}/${ARCHIVE_NAME}.tar.gz"
    tar --strip-components=1 -zxmf "${CACHEDIR}/${ARCHIVE_NAME}.tar.gz" -C "$WP_CORE_DIR"
  fi

  if [ "$WP_USE_SQLITE" == "true" ]; then
    if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
      green "Installing sqlite-database-integration plugin"
    fi

    download "https://github.com/WordPress/sqlite-database-integration/archive/refs/heads/main.zip" "$CACHEDIR/sqlite-database-integration-main.zip"

    unzip -q "$CACHEDIR/sqlite-database-integration-main.zip" -d "$WP_CORE_DIR/wp-content/plugins"

    if [ -d "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration-main" ]; then
      if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
        yellow "Renaming sqlite-database-integration-main to sqlite-database-integration"
      fi

      mv "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration-main" "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration"
    fi

    # Copy the db.php file to the wp-content directory.
    if [ -f "$WP_CORE_DIR/wp-content/db.php" ]; then
      yellow "db.php already exists, skipping"
    else
      if [ -f "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration/db.copy" ]; then
        if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
          green "Copying SQLite db.php drop-in"
        fi

        cp "$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration/db.copy" "$WP_CORE_DIR/wp-content/db.php"
      else
        red "SQLite db.php drop-in not found at [$WP_CORE_DIR/wp-content/plugins/sqlite-database-integration/db.copy]"
      fi
    fi
  else
    if [ "$INSTALL_WP_TEST_DEBUG" = "true" ]; then
      green "Installing mysqli db.php drop-in"
    fi

    download https://raw.githubusercontent.com/markoheijnen/wp-mysqli/master/db.php "$WP_CORE_DIR/wp-content/db.php"
  fi
}

install_config() {
  # portable in-place argument for both GNU sed and Mac OSX sed
  if [[ $(uname -s) == 'Darwin' ]]; then
    local ioption='-i.bak'
  else
    local ioption='-i'
  fi

  green "Installing wp-tests-config.php"

  if [ ! -f wp-tests-config.php ]; then
    download https://raw.githubusercontent.com/alleyinteractive/mantle-ci/HEAD/wp-tests-config-sample.php "$WP_CORE_DIR/wp-tests-config.php"

    # remove all forward slashes in the end
    # shellcheck disable=SC2001
    WP_CORE_DIR=$(echo "$WP_CORE_DIR" | sed "s:/\+$::")

    sed $ioption "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_CORE_DIR"/wp-tests-config.php
    sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" "$WP_CORE_DIR"/wp-tests-config.php
    sed $ioption "s/yourusernamehere/$DB_USER/" "$WP_CORE_DIR"/wp-tests-config.php
    sed $ioption "s/yourpasswordhere/$DB_PASS/" "$WP_CORE_DIR"/wp-tests-config.php
    sed $ioption "s|localhost|${DB_HOST}|" "$WP_CORE_DIR"/wp-tests-config.php
  fi
}

install_test_suite() {
  if [ "$WP_INSTALL_CORE_TEST_SUITE" != "true" ]; then
    yellow "Skipping installing core test suite"
    return
  fi

  green "Installing core test suite to $WP_TESTS_DIR"

  # portable in-place argument for both GNU sed and Mac OSX sed
  if [[ $(uname -s) == 'Darwin' ]]; then
    local ioption='-i .bak'
  else
    local ioption='-i'
  fi

  # Grab a copy of wordpress-develop with the requested branch or tag.
  git clone --depth=1 --quiet --branch="$WP_TESTS_TAG" https://github.com/wordpress/wordpress-develop /tmp/wordpress-develop-github

  # set up testing suite if it doesn't yet exist
  if [ ! -d "$WP_TESTS_DIR" ]; then
    # set up testing suite
    mkdir -p "$WP_TESTS_DIR"
    cp -r /tmp/wordpress-develop-github/tests/phpunit/includes "$WP_TESTS_DIR"
    cp -r /tmp/wordpress-develop-github/tests/phpunit/data "$WP_TESTS_DIR"
  fi

  if [ ! -f wp-tests-config.php ]; then
    cp /tmp/wordpress-develop-github/wp-tests-config-sample.php "$WP_TESTS_DIR/wp-tests-config.php"

    # Remove the trailing forward slash
    # shellcheck disable=SC2001
    WP_CORE_DIR=$(echo "$WP_CORE_DIR" | sed "s:/\+$::")

    sed "$ioption" "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_TESTS_DIR"/wp-tests-config.php
    sed "$ioption" "s/youremptytestdbnamehere/$DB_NAME/" "$WP_TESTS_DIR"/wp-tests-config.php
    sed "$ioption" "s/yourusernamehere/$DB_USER/" "$WP_TESTS_DIR"/wp-tests-config.php
    sed "$ioption" "s/yourpasswordhere/$DB_PASS/" "$WP_TESTS_DIR"/wp-tests-config.php
    sed "$ioption" "s|localhost|${DB_HOST}|" "$WP_TESTS_DIR"/wp-tests-config.php
  fi
}

install_db() {
  if [ "${SKIP_DB_CREATE}" = "true" ]; then
    yellow "Skipping database creation"
    return
  fi

  green "Creating database $DB_NAME"

  # parse DB_HOST for port or socket references
  local PARTS=("${DB_HOST//:/ }")
  local DB_HOSTNAME=${PARTS[0]}
  local DB_SOCK_OR_PORT=${PARTS[1]}
  local EXTRA=""

  if [ -n "$DB_HOSTNAME" ]; then
    if echo "$DB_SOCK_OR_PORT" | grep -q -e '^[0-9]\{1,\}$'; then
      EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
    elif [ -n "$DB_SOCK_OR_PORT" ]; then
      EXTRA=" --socket=$DB_SOCK_OR_PORT"
    elif [ -n "$DB_HOSTNAME" ]; then
      EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
    fi
  fi

  # Drop the database if it exists.
  # shellcheck disable=SC2086
  mysqladmin drop "$DB_NAME" -f --user="$DB_USER" --password="$DB_PASS"$EXTRA || true

  # Create the new databaase.
  # shellcheck disable=SC2086
  mysqladmin create "$DB_NAME" --user="$DB_USER" --password="$DB_PASS"$EXTRA
}

install_vip_mu_plugins() {
  if [ "$INSTALL_VIP_MU_PLUGINS" != "true" ]; then
    yellow "Skipping installing mu-plugins"
    return
  fi

  green "Cloning VIP Go mu-plugins"

  cd "${WP_CORE_DIR}/wp-content/"

  # Checkout VIP Go mu-plugins to mu-plugins
  if [ ! -d "mu-plugins" ]; then
    git clone \
      --quiet \
      --recursive \
      --depth=1 \
      https://github.com/Automattic/vip-go-mu-plugins-built.git mu-plugins
  else
    # Check if this is a Git clone of the built mu-plugins. Bail out if it is not.
    if [ ! -d "mu-plugins/.git" ]; then
      red "mu-plugins already exists and is not a Git clone, aborting"
      return
    fi

    yellow "VIP Go mu-plugins already exists, attempting to update"
    cd mu-plugins
    git pull
    cd ..
  fi

  # Install the `000-pre-vip-config/requires.php` to the test configuration if
  # the file isn't already modified.
  #
  # see: https://docs.wpvip.com/how-tos/third-party-local-development/#h-step-4-update-wp-config-php
  if [ -f "$WP_CORE_DIR/wp-tests-config.php" ] && ! grep -q "000-pre-vip-config/requires.php" "$WP_CORE_DIR/wp-tests-config.php"; then
    printf "\\n// Load early dependencies\\nif ( file_exists( ABSPATH . 'wp-content/mu-plugins/000-pre-vip-config/requires.php' ) ) require_once ABSPATH . 'wp-content/mu-plugins/000-pre-vip-config/requires.php';\\n" >> "$WP_CORE_DIR/wp-tests-config.php"

    green "Added 000-pre-vip-config/requires.php to wp-tests-config.php"
  fi
}

# Install the vip-config/vip-config.php file to the test configuration
#
# see: https://docs.wpvip.com/how-tos/third-party-local-development/#h-step-4-update-wp-config-php
install_vip_config() {
  # Prevent installation of the vip-config.php into wp-config.php if disabled OR
  # if VIP's mu-plugins are not installed.
  if [ "$INSTALL_VIP_CONFIG" != "true" ] || [ ! -f "${WP_CORE_DIR}/wp-content/mu-plugins/000-pre-vip-config/requires.php" ]; then
    yellow "Skipping vip-config/vip-config.php installation to wp-tests-config.php"
    return
  fi

  if [ ! -f "$WP_CORE_DIR/wp-tests-config.php" ]; then
    red "wp-tests-config.php does not exist, aborting"
    return
  fi

  # Check if the modification to wp-tests-config.php has already been made.
  if grep -q "vip-config.php" "$WP_CORE_DIR/wp-tests-config.php"; then
    yellow "vip-config.php already included in wp-tests-config.php, skipping"
    return
  fi

  printf "\\n// Load the vip-config/vip-config.php file if it exists.\\nif ( file_exists( ABSPATH . 'wp-content/vip-config/vip-config.php' ) ) require_once ABSPATH . 'wp-content/vip-config/vip-config.php';\\n" >> "$WP_CORE_DIR/wp-tests-config.php"

  green "Added vip-config/vip-config.php to wp-tests-config.php"
}

install_object_cache() {
  if [ "$INSTALL_OBJECT_CACHE" == "false" ]; then
    yellow "Skipping installing object-cache.php"
    return
  fi

  # Check if the file exists.
  if [ -f "${WP_CORE_DIR}/wp-content/object-cache.php" ]; then
    yellow "object-cache.php already exists, skipping"
    return
  fi

  # Install the object-cache.php file for Memcached.
  if [ "$INSTALL_OBJECT_CACHE" == "true" ] || [ "$INSTALL_OBJECT_CACHE" == "memcached" ]; then
    # If we're installing mu-plugins, symlink the object-cache.php file from the
    # mu-plugins installation. Otherwise, download it from wp-memcached.
    if [ "$INSTALL_VIP_MU_PLUGINS" == "true" ] || [ -f "${WP_CORE_DIR}/wp-content/mu-plugins/drop-ins/object-cache.php" ]; then
      green "Symlinking object-cache.php from VIP Go mu-plugins"
      ln -s "${WP_CORE_DIR}/wp-content/mu-plugins/drop-ins/object-cache.php" "${WP_CORE_DIR}/wp-content/object-cache.php"
    else
      green "Downloading object-cache.php from wp-memcached"
      download "https://raw.githubusercontent.com/Automattic/wp-memcached/HEAD/object-cache.php" "${WP_CORE_DIR}/wp-content/object-cache.php"
    fi
    return
  fi

  # Install the object-cache.php file for Redis.
  if [ "$INSTALL_OBJECT_CACHE" == "redis" ]; then
    green "Downloading object-cache.php from wp-redis"
    download "https://raw.githubusercontent.com/pantheon-systems/wp-redis/HEAD/object-cache.php" "${WP_CORE_DIR}/wp-content/object-cache.php"
    return
  fi
}

install_wp
install_test_suite
install_config
install_db
install_vip_mu_plugins
install_vip_config
install_object_cache

green "Ready to test ${WP_CORE_DIR}/wp-content/ 🚀"
