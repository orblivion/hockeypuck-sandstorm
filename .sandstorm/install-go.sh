#!/bin/bash
set -euox pipefail
here="$(dirname "$(readlink -f "$0")")"
cd "$here"

# https://golang.org/doc/install
wget https://golang.org/dl/go1.21.6.linux-amd64.tar.gz -O /tmp/golang.tar.gz
sha256sum --strict -c downloads/golang.checksum

# https://golang.org/doc/install
rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/golang.tar.gz

export PATH=$PATH:/usr/local/go/bin

go version
