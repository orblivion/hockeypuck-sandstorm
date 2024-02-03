#!/usr/bin/bash
set -euo pipefail

# Launch the berkut application.
#
# Steps:
#   - Ensure that the necessary directories exist and are in a known state.
#   - Start PostgreSQL.
#   - Migrate databases if necessary.
#   - Start Uvicorn.
#   - Start nginx.

. /opt/app/.sandstorm/environment

# Clean up
/usr/bin/rm -rf /var/run
/usr/bin/rm -rf /var/tmp
# Create folders
#mkdir -p "$POSTGRESQL_DATA"
/usr/bin/mkdir -p "$POSTGRESQL_RUN"
/usr/bin/mkdir -p "$NGLIB"
/usr/bin/mkdir -p "$NGLOG"
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
/usr/bin/mkdir -p /var/run
/usr/bin/mkdir -p /var/tmp

# PostgreSQL likes to map effective user IDs to names through calls to getpwuid.
# Create temporary passwd and group databases.
PASSWD_FILE=$(mktemp)
echo "user:x:$(geteuid):$(getegid):PostgreSQL administrator,,,:/tmp:/usr/bin/bash" > "$PASSWD_FILE"
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
LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD="$PASSWD_FILE" NSS_WRAPPER_GROUP="$GROUP_FILE" NSS_WRAPPER_HOSTS="$HOSTS_FILE" /usr/bin/createdb --encoding=UTF-8 --locale=en_US.UTF-8 --template=template0 --owner=user "$POSTGRESQL_DB_NAME" "$POSTGRESQL_DB_DESCRIPTION" || true

# Apply database migrations
echo "Applying database migrations..."
PYTHONPATH="/opt/app" "$VENV_PYTHON" "$DJANGO_MANAGE" migrate --database=default

echo "Removing stale content types..."
PYTHONPATH="/opt/app" "$VENV_PYTHON" "$DJANGO_MANAGE" remove_stale_contenttypes --no-input

echo "Removing expired user sessions..."
PYTHONPATH="/opt/app" "$VENV_PYTHON" "$DJANGO_MANAGE" clearsessions

# Start Uvicorn
PYTHONPATH="/opt/app:$DJANGO_ROOT"    \
    "$VENV_PYTHON"                              \
    "$DJANGO_ROOT"/django_project/server.py &

# Wait for Uvicorn to bind its socket
for (( i = 1; i <= 100; i++ )); do
    if [ -e "$UVICORN_SOCKET" ]; then
        echo "found Uvicorn socket at $UVICORN_SOCKET"
        break
    elif [ $i -eq 100 ]; then
        echo "Uvicorn failed to start.  Goodbye fair earth."
        exit 1
    else
        echo "Waiting for Uvicorn to be available at $UVICORN_SOCKET"
        sleep 0.125
    fi
done

# Start nginx.
"$NGINX" -c "$SERVICE_CONFIG"/nginx.conf -g "daemon off;"
