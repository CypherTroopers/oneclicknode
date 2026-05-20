#!/bin/bash
set -euo pipefail

if ! command -v go >/dev/null 2>&1; then
  if [ -x /usr/local/go/bin/go ]; then
    export PATH="/usr/local/go/bin:$PATH"
  fi
fi

GOPATH="${GOPATH:-$(go env GOPATH 2>/dev/null || true)}"
if [[ -z "${GOPATH}" ]]; then
  GOPATH="/root/go"
fi
mkdir -p "$GOPATH/src/github.com/cypherium"
cd "$GOPATH/src/github.com/cypherium"

if [ ! -d cypher/.git ]; then
  git clone https://github.com/CypherTroopers/cypher.git
fi

cd cypher
