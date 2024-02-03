#!/bin/bash
here="$(dirname "$(readlink -f "$0")")"
cd "$here"

set -exuo pipefail

cd /opt/app

ls hockeypuck || git clone https://github.com/hockeypuck/hockeypuck

cd hockeypuck

git checkout db0a441dede5a406258d0ea329bf219f101e85e4

export PATH=$PATH:/usr/local/go/bin

make build
