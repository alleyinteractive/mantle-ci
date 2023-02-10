#!/usr/bin/env bash

WP_VERSION=${1-latest}

CACHEDIR=${CACHEDIR-/tmp}
CACHEDIR=$(echo $CACHEDIR | sed -e "s/\/$//")

WP_CORE_DIR=${WP_CORE_DIR-$CACHEDIR/wordpress/}
# MANTLE_CI_TREE=${MANTLE_CI_TREE-HEAD}
MANTLE_CI_TREE=${MANTLE_CI_TREE-sqlite-plugin}

# Create the cache directory if it doesn't exist.
mkdir -p $CACHEDIR


download() {
	# Check if the file has been downloaded in the last couple of hours.
	# If it has been, use it instead of downloading it again.
	if [[ -f $2 ]]; then
		if test "$(find $2 -mmin -240)"; then
			return
		fi
	fi

	if [ $(which curl) ]; then
		curl -f -s "$1" > "$2"
	elif [ $(which wget) ]; then
		wget -nv -O "$2" "$1"
	fi

	# Exit if the last command failed.
	if [ $? -ne 0 ]; then
		echo "Downloading $1 failed"
		exit 1
	fi
}

if [[ $WP_VERSION =~ ^[0-9]+\.[0-9]+\-(beta|RC)[0-9]+$ ]]; then
	WP_BRANCH=${WP_VERSION%\-*}
	WP_TESTS_TAG="branches/$WP_BRANCH"

elif [[ $WP_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
	WP_TESTS_TAG="branches/$WP_VERSION"
elif [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
	if [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0] ]]; then
		# version x.x.0 means the first release of the major version, so strip off the .0 and download version x.x
		WP_TESTS_TAG="tags/${WP_VERSION%??}"
	else
		WP_TESTS_TAG="tags/$WP_VERSION"
	fi
elif [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
	WP_TESTS_TAG="trunk"
else
	# http serves a single offer, whereas https serves multiple. we only want one
	download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
	grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
	LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
	if [[ -z "$LATEST_VERSION" ]]; then
		echo "Latest WordPress version could not be found"
		exit 1
	fi
	WP_TESTS_TAG="tags/$LATEST_VERSION"
fi

set -e

install_wp() {
	if [ -d $WP_CORE_DIR ]; then
		if [ -f $WP_CORE_DIR/wp-load.php ]; then
			echo "WordPress already installed at [$WP_CORE_DIR]"
			return
		fi
	fi

	mkdir -p $WP_CORE_DIR

	if [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
		mkdir -p $CACHEDIR/wordpress-nightly
		download https://wordpress.org/nightly-builds/wordpress-latest.zip  $CACHEDIR/wordpress-nightly/wordpress-nightly.zip
		unzip -q $CACHEDIR/wordpress-nightly/wordpress-nightly.zip -d $CACHEDIR/wordpress-nightly/
		mv $CACHEDIR/wordpress-nightly/wordpress/* $WP_CORE_DIR
	else
		if [ $WP_VERSION == 'latest' ]; then
			local ARCHIVE_NAME='latest'
		elif [[ $WP_VERSION =~ [0-9]+\.[0-9]+ ]]; then
			# https serves multiple offers, whereas http serves single.
			download https://api.wordpress.org/core/version-check/1.7/ $CACHEDIR/wp-latest.json
			if [[ $WP_VERSION =~ [0-9]+\.[0-9]+\.[0] ]]; then
				# version x.x.0 means the first release of the major version, so strip off the .0 and download version x.x
				LATEST_VERSION=${WP_VERSION%??}
			else
				# otherwise, scan the releases and get the most up to date minor version of the major release
				local VERSION_ESCAPED=$(echo $WP_VERSION | sed 's/\./\\\\./g')
				LATEST_VERSION=$(grep -o '"version":"'$VERSION_ESCAPED'[^"]*' $CACHEDIR/wp-latest.json | sed 's/"version":"//' | head -1)
			fi
			if [[ -z "$LATEST_VERSION" ]]; then
				local ARCHIVE_NAME="wordpress-$WP_VERSION"
			else
				local ARCHIVE_NAME="wordpress-$LATEST_VERSION"
			fi
		else
			local ARCHIVE_NAME="wordpress-$WP_VERSION"
		fi
		download https://wordpress.org/${ARCHIVE_NAME}.tar.gz  $CACHEDIR/wordpress.tar.gz
		tar --strip-components=1 -zxmf $CACHEDIR/wordpress.tar.gz -C $WP_CORE_DIR
	fi
}

install_config() {
	# portable in-place argument for both GNU sed and Mac OSX sed
	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i.bak'
	else
		local ioption='-i'
	fi

	if [ ! -f wp-tests-config.php ]; then
		download https://raw.githubusercontent.com/alleyinteractive/mantle-ci/$MANTLE_CI_TREE/wp-tests-config-sample.php "$WP_CORE_DIR"/wp-tests-config.php
		# remove all forward slashes in the end
		WP_CORE_DIR=$(echo $WP_CORE_DIR | sed "s:/\+$::")
		sed $ioption "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_CORE_DIR"/wp-tests-config.php
		sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" "$WP_CORE_DIR"/wp-tests-config.php
		sed $ioption "s/yourusernamehere/$DB_USER/" "$WP_CORE_DIR"/wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" "$WP_CORE_DIR"/wp-tests-config.php
		sed $ioption "s|localhost|${DB_HOST}|" "$WP_CORE_DIR"/wp-tests-config.php
	fi
}

install_sqlite() {
	download https://raw.githubusercontent.com/alleyinteractive/mantle-ci/$MANTLE_CI_TREE/sqlite/wp-content/db.php "$WP_CORE_DIR"/wp-content/db.php

	mkdir -p "$WP_CORE_DIR/wp-includes/sqlite"

	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-alter-query.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-alter-query.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-create-query.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-create-query.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-db.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-db.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-object-array.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-object-array.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-pdo-driver.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-pdo-driver.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-pdo-engine.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-pdo-engine.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/class-wp-sqlite-pdo-user-defined-functions.php "$WP_CORE_DIR/wp-includes/sqlite/class-wp-sqlite-pdo-user-defined-functions.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/constants.php "$WP_CORE_DIR/wp-includes/sqlite/constants.php"
	download https://raw.githubusercontent.com/WordPress/sqlite-database-integration/v1.0.3/wp-includes/sqlite/install-functions.php "$WP_CORE_DIR/wp-includes/sqlite/install-functions.php"
}

install_wp
install_config
install_sqlite