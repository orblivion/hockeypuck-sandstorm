#!/bin/bash
here="$(dirname "$(readlink -f "$0")")"
cd "$here"

set -exuo pipefail

export PATH=$PATH:/usr/local/go/bin

cd /opt/app/hockeypuck/src/hockeypuck
go get -u -m
go mod vendor
