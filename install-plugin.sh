#!/usr/bin/env bash
set -e

# Install Plugins to a WordPress Installation
#
# Used during CI to install plugins to a WordPress installation for testing.
#
# Usage:
#
#   install-plugin.sh <plugin-slug> <version>
#   install-plugin.sh <plugin-slug> <plugin-zip-url>
#
# Arguments:
#
#   <plugin-slug>   The slug of the plugin to install from the WordPress.org
#                   plugin repository.
#   <version>       The version of the plugin to install OR a URL to a zip file
#                   of the plugin to install.
#
# Environment Variables:
#
# 	CACHEDIR: The location of the cache directory.
# 		Defaults to /tmp.
# 	WP_CORE_DIR: The location of the WordPress core directory.
# 		Defaults to /tmp/wordpress.
#
# Example:
#
#   install-plugin.sh bbpress 2.6.4
#   install-plugin.sh logger https://github.com/alleyinteractive/logger/archive/refs/heads/develop.zip

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

# Arguments passed to the script.
PLUGIN_SLUG=$1
PLUGIN_VERSION="${2:-latest}"
PLUGIN_FILE_NAME="${PLUGIN_SLUG}.zip"

# Check if the URL was bassed to the slug argument.
if [[ $PLUGIN_SLUG =~ ^https?://.*\.zip$ ]]; then
  red "The plugin slug cannot be a URL to a zip file. Please pass the plugin slug as the first argument and the plugin URL/version as the second argument."
  exit 1
fi

# Check if the plugin version is a URL to a zip file.
if [[ $PLUGIN_VERSION =~ ^https?://.*\.zip$ ]]; then
  PLUGIN_ZIP_URL=$PLUGIN_VERSION

  # Set the plugin file name equal to the md5 of the URL.
  PLUGIN_FILE_NAME="$PLUGIN_SLUG-$(echo "$PLUGIN_ZIP_URL" | md5sum | awk '{ print $1 }').zip"
elif [[ $PLUGIN_VERSION == "latest" ]]; then
  PLUGIN_ZIP_URL="https://downloads.wordpress.org/plugin/${PLUGIN_SLUG}.zip"
else
  PLUGIN_ZIP_URL="https://downloads.wordpress.org/plugin/${PLUGIN_SLUG}.${PLUGIN_VERSION}.zip"
fi

# Environment variables with defaults.
CACHEDIR=${CACHEDIR:-/tmp}
CACHEDIR=$(echo "$CACHEDIR" | sed -e "s/\/$//") # Remove trailing slash if present.
WP_CORE_DIR=${WP_CORE_DIR:-"${CACHEDIR}/wordpress"}

# Create the cache directory if it doesn't exist.
mkdir -p "$CACHEDIR"

# Create the plugins directory if it doesn't exist.
mkdir -p "$WP_CORE_DIR/wp-content/plugins"

# Method to download a file.
download() {
  # Check if the file has been downloaded in the last 72 hours.
  # If it has been, use it instead of downloading it again.
  if [[ -f $2 ]]; then
    if test "$(find "$2" -mtime -3)"; then
      yellow "Using cached $2"

      return
    fi
  fi

  set +e

  if command -v curl >/dev/null 2>&1; then
    curl -L -f -s "$1" > "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -nv -O "$2" "$1"
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

  set -e
}

# Bail if the plugin is already installed.
if [[ -d "${WP_CORE_DIR}/wp-content/plugins/${PLUGIN_SLUG}" ]]; then
  yellow "The plugin ${PLUGIN_SLUG} is already installed."
  exit 0
fi

yellow "Downloading ${PLUGIN_SLUG} plugin from ${PLUGIN_ZIP_URL} to ${CACHEDIR}/${PLUGIN_FILE_NAME}"

download "$PLUGIN_ZIP_URL" "${CACHEDIR}/${PLUGIN_FILE_NAME}"

yellow "Extracting from ${CACHEDIR}/${PLUGIN_FILE_NAME} to ${CACHEDIR}/plugins/${PLUGIN_SLUG}"

if [[ -d "${CACHEDIR}/plugins/${PLUGIN_SLUG}" ]]; then
  rm -rf "${CACHEDIR}/plugins/${PLUGIN_SLUG}"
fi

mkdir -p "${CACHEDIR}/plugins/${PLUGIN_SLUG}"
unzip -q "${CACHEDIR}/${PLUGIN_FILE_NAME}" -d "${CACHEDIR}/plugins/${PLUGIN_SLUG}"

yellow "Copying ${CACHEDIR}/plugins/${PLUGIN_SLUG} to ${WP_CORE_DIR}/wp-content/plugins/${PLUGIN_SLUG}"

cd "${CACHEDIR}/plugins/${PLUGIN_SLUG}"

# Check if the extracted plugin directory contains a single directory.
# If it does, move the contents of that directory to the plugin directory.
# This is to account for plugins that are packaged with a parent directory.
if [[ $(find . -maxdepth 1 -type d | wc -l) -eq 2 ]]; then
  cd "$(find . -maxdepth 1 -type d | tail -n 1)"
fi

rsync -r . "${WP_CORE_DIR}/wp-content/plugins/${PLUGIN_SLUG}"
rm -rf "${CACHEDIR}/plugins/${PLUGIN_SLUG}"

green "${PLUGIN_SLUG} plugin installed successfully."
