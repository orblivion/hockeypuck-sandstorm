#!/usr/bin/bash
set -euo pipefail

# Steps:
#   - Ensure that the necessary directories exist and are in a known state.
#   - Start PostgreSQL.
#   - Migrate databases if necessary.

. /opt/app/.sandstorm/environment

# Clean up
/usr/bin/rm -rf /var/run
/usr/bin/rm -rf /var/tmp
# Create folders
#mkdir -p "$POSTGRESQL_DATA"
/usr/bin/mkdir -p "$POSTGRESQL_RUN"
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
/usr/bin/mkdir -p /var/run
/usr/bin/mkdir -p /var/tmp

# PostgreSQL likes to map effective user IDs to names through calls to getpwuid.
# Create temporary passwd and group databases.
PASSWD_FILE=$(mktemp)
echo "vagrant:x:$(geteuid):$(getegid):PostgreSQL administrator,,,:/tmp:/usr/bin/bash" > "$PASSWD_FILE"
GROUP_FILE=$(mktemp)
echo "postgres:x:$(getegid):" > "$GROUP_FILE"
HOSTS_FILE=$(mktemp)
echo "127.0.0.1 localhost" >> "$HOSTS_FILE"
echo "::1 localhost" >> "$HOSTS_FILE"

# Create PostgreSQL database files
if [ ! -d "$POSTGRESQL_DATA" ]; then
        LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD="$PASSWD_FILE" NSS_WRAPPER_GROUP="$GROUP_FILE" NSS_WRAPPER_HOSTS="$HOSTS_FILE" "$POSTGRESQL_BIN"/initdb --pgdata="$POSTGRESQL_DATA" --encoding=UTF-8 --locale=en_US.UTF-8
fi
# Cloning a grain resulted in incorrect permissions being applied.
# PostgreSQL will refuse to start if these permissions are not 0700 or 0750.
chmod 0750 "$POSTGRESQL_DATA"

# Start PostgreSQL
LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD="$PASSWD_FILE" NSS_WRAPPER_GROUP="$GROUP_FILE" NSS_WRAPPER_HOSTS="$HOSTS_FILE" "$POSTGRESQL_BIN"/postgres --config-file="$SERVICE_CONFIG"/postgresql.conf &

# Wait for PostgreSQL to bind its socket
for (( i = 1; i <= 10; i++ )); do
    if [ -e "$POSTGRESQL_SOCKET" ]; then
        echo "found PostgreSQL socket at $POSTGRESQL_SOCKET"
        break
    elif [ $i -eq 10 ]; then
        echo "PostgreSQL failed to start.  Goodbye fair earth."
        exit 1
    else
        echo "waiting for PostgreSQL to be available at $POSTGRESQL_SOCKET"
        sleep 0.125
    fi
done

# Create the database if it does not already exist.
LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD="$PASSWD_FILE" NSS_WRAPPER_GROUP="$GROUP_FILE" NSS_WRAPPER_HOSTS="$HOSTS_FILE" /usr/bin/createdb --encoding=UTF-8 --locale=en_US.UTF-8 --template=template0 --owner=vagrant "$POSTGRESQL_DB_NAME" "$POSTGRESQL_DB_DESCRIPTION" || true

mkdir -p /var/lib/hockeypuck/leveldb
mkdir -p /var/log/hockeypuck
/opt/app/hockeypuck/bin/hockeypuck -config /opt/app/hockeypuck.conf
