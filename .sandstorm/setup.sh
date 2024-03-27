#!/usr/bin/bash

# When you change this file, you must take manual action. Read this doc:
# - https://docs.sandstorm.io/en/latest/vagrant-spk/customizing/#setupsh

set -euo pipefail

. /opt/app/.sandstorm/environment

# Add the PostgreSQL Global Development Group's repository to APT.
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
cp "$DOWNLOADS"/postgresql-release-key-"$POSTGRESQL_RELEASE_KEY".asc /etc/apt/trusted.gpg.d

APT_PREREQS="gnupg"
APT_L10N_REQS="gettext"
APT_UTILS_REQS="build-essential"

# Update APT's cache and install outstanding upgrades.
apt-get update && apt-get upgrade -y

# Install pre-requisite packages.
apt-get install -y $APT_PREREQS $APT_L10N_REQS $APT_UTILS_REQS

# libnss-wrapper is needed to run PostgreSQL inside the Sandstorm sandbox
# libpq-dev is needed to install psycopg2 from requirements.txt
apt-get install -y nginx postgresql-"$POSTGRESQL_MAJOR_VERSION" libnss-wrapper libpq-dev
service nginx stop
service postgresql@"$POSTGRESQL_MAJOR_VERSION"-main stop
systemctl disable nginx
systemctl disable postgresql@"$POSTGRESQL_MAJOR_VERSION"-main

# Build and install utilities
make -C /opt/app/util all install clean

# Generate en_US.UTF-8 locale for use by PostgreSQL
PATCH=$(patch --forward /etc/locale.gen "$PATCHES"/locale.gen.diff) || echo "${PATCH}" | grep "Skipping patch" -q || (echo "${PATCH}" && false)
locale-gen
