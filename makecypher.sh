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

if ls ./crypto/bls/lib/linux/* >/dev/null 2>&1; then
  cp -f ./crypto/bls/lib/linux/* ./crypto/bls/lib/
fi
mkdir -p "$GOPATH/src/github.com/VictoriaMetrics"
cd "$GOPATH/src/github.com/VictoriaMetrics"
[ -d fastcache/.git ] || git clone https://github.com/VictoriaMetrics/fastcache.git

mkdir -p "$GOPATH/src/github.com/shirou"
cd "$GOPATH/src/github.com/shirou"
[ -d gopsutil/.git ] || git clone https://github.com/shirou/gopsutil.git

mkdir -p "$GOPATH/src/github.com/dlclark"
cd "$GOPATH/src/github.com/dlclark"
[ -d regexp2/.git ] || git clone https://github.com/dlclark/regexp2.git

mkdir -p "$GOPATH/src/github.com/go-sourcemap"
cd "$GOPATH/src/github.com/go-sourcemap"
[ -d sourcemap/.git ] || git clone https://github.com/go-sourcemap/sourcemap.git

mkdir -p "$GOPATH/src/github.com/tklauser"
cd "$GOPATH/src/github.com/tklauser"
[ -d go-sysconf/.git ] || git clone https://github.com/tklauser/go-sysconf.git
[ -d numcpus/.git ] || git clone https://github.com/tklauser/numcpus.git

mkdir -p "$GOPATH/src/golang.org/x"
cd "$GOPATH/src/golang.org/x"
[ -d sys/.git ] || git clone https://go.googlesource.com/sys
DUK_LOGGING_PATH="$GOPATH/src/github.com/cypherium/cypher/vendor/gopkg.in/olebedev/go-duktape.v3/duk_logging.c"
if [ -f "$DUK_LOGGING_PATH" ]; then
  sed -i 's/duk_uint8_t date_buf\[32\]/duk_uint8_t date_buf[64]/' "$DUK_LOGGING_PATH" || true
  sed -i 's/sprintf((char \*) date_buf,/snprintf((char *) date_buf, sizeof(date_buf),/g' "$DUK_LOGGING_PATH" || true
fi
cd "$GOPATH/src/github.com/cypherium/cypher"

git checkout -- vendor/github.com/fjl/memsize/memsize.go \
               vendor/gopkg.in/olebedev/go-duktape.v3/duk_logging.c 2>/dev/null || true

# re-apply duk patch after revert
if [ -f "$DUK_LOGGING_PATH" ]; then
  sed -i 's/duk_uint8_t date_buf\[32\]/duk_uint8_t date_buf[64]/' "$DUK_LOGGING_PATH" || true
  sed -i 's/sprintf((char \*) date_buf,/snprintf((char *) date_buf, sizeof(date_buf),/g' "$DUK_LOGGING_PATH" || true
fi

MEMSIZE_PATH="vendor/github.com/fjl/memsize/memsize.go"
if [ -f "$MEMSIZE_PATH" ]; then
  perl -0777 -i -pe '
    my @l = split(/\n/,$_);
    for (@l) {
      if (/stopTheWorld\(/ && !/func\s+stopTheWorld/ && !/go:linkname/) { s/^(\s*)/$1\/\/ /; }
      if (/startTheWorld\(/ && !/func\s+startTheWorld/ && !/go:linkname/) { s/^(\s*)/$1\/\/ /; }
    }
    $_ = join("\n",@l);
  ' "$MEMSIZE_PATH"
fi

make clean
make cypher
