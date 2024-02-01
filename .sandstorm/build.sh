#!/usr/bin/bash
set -euo pipefail

. /opt/app/.sandstorm/environment

cd /opt/app

# Initialize the virtual environment.
if [ ! -f "$VENV_PYTHON" ] && [ ! -f "$VENV_PIP" ] ; then
    if [ ! -d "$VENV" ] ; then
        sudo mkdir "$VENV"
    fi
    sudo chown -R "$VAGRANT_USER" "$VENV"
    sudo chgrp -R "$VAGRANT_GROUP" "$VENV"
    "$PYTHON" -m venv --copies --clear --upgrade-deps "$VENV"
    "$VENV_PIP" install wheel
fi

# Install dependencies from requirements.txt.
if [ -f /opt/app/requirements.txt ] ; then
    "$VENV_PIP" install -r /opt/app/requirements.txt
fi

# Collect static files.
/usr/bin/rm -rf "$STATIC_ROOT" && /usr/bin/mkdir "$STATIC_ROOT"
PYTHONPATH="." "$VENV_PYTHON" "$DJANGO_MANAGE" collectstatic --no-input
