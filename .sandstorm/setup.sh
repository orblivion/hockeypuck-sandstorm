#!/usr/bin/bash

# When you change this file, you must take manual action. Read this doc:
# - https://docs.sandstorm.io/en/latest/vagrant-spk/customizing/#setupsh

set -euo pipefail

. /opt/app/.sandstorm/environment

# Python
#
# If you desire better performance from Python or a Python newer than 3.9,
# you'll want to build it from source.  (Python 3.9 security updates end
# October, 2025.)  Building from source and running the tests in a VirtualBox
# VM requires about 30 on a 2015 MacBook Pro.
#
# If you need tkinter support, add tk-dev to APT_PYTHON_FROM_SOURCE_REQS.
#
# If you choose to use the Python interpreter that ships with Debian, you'll
# need to update the PYTHON and PYTHON_PLUS_VERSION values in the environment
# file.
PYTHON_BUILD_FROM_SOURCE=yes

export DEBIAN_FRONTEND=noninteractive

# Add the PostgreSQL Global Development Group's repository to APT.
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
cp "$DOWNLOADS"/postgresql-release-key-"$POSTGRESQL_RELEASE_KEY".asc /etc/apt/trusted.gpg.d

APT_PREREQS="gnupg"
APT_L10N_REQS="gettext"
APT_PYTHON_FROM_SOURCE_REQS="libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev libncurses5-dev libnss3-dev libreadline-dev libsqlite3-dev libssl-dev libxml2-dev libxslt1-dev pkg-config uuid-dev zlib1g-dev"
APT_UTILS_REQS="build-essential"

if [ "$PYTHON_BUILD_FROM_SOURCE" = "no" ]; then
	APT_PYTHON_REQS="python3-venv"
else
	APT_PYTHON_REQS="$APT_PYTHON_FROM_SOURCE_REQS"
fi

# Update APT's cache and install outstanding upgrades.
apt-get update && apt-get upgrade -y

# Install pre-requisite packages.
apt-get install -y $APT_PREREQS $APT_L10N_REQS $APT_PYTHON_REQS $APT_UTILS_REQS

if [ ! -f "$PYTHON" ] || [ "$PYTHON_VERSION" != "$($PYTHON -V | awk '{print $2}')" ]; then
    # Get Python
    $CURL -O https://www.python.org/ftp/python/"$PYTHON_VERSION"/Python-"$PYTHON_VERSION".tar.xz
    gpg --import "$DOWNLOADS"/Python-"$PYTHON_VERSION"-release-key-"$PYTHON_RELEASE_KEY".asc
    gpg --verify "$DOWNLOADS"/Python-"$PYTHON_VERSION".tar.xz.asc Python-"$PYTHON_VERSION".tar.xz

    # Build and install Python
    tar Jxf Python-"$PYTHON_VERSION".tar.xz
    cd Python-"$PYTHON_VERSION"
    # Python tests fail intermittently because of nntplib
    LDFLAGS="-Wl,--enable-new-dtags -Wl,-rpath,$PYTHON_PREFIX/lib" ./configure --prefix="$PYTHON_PREFIX" --enable-optimizations --enable-shared && make && ( make test || true ) && make install
    cd ..
fi

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
