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

CY_DIR="$GOPATH/src/github.com/cypherium/cypher"
DATADIR="$CY_DIR/chaindbname"
DEST="$DATADIR/cypher"

TAR="chaindata0-263866.tar.zst"
SHA="${TAR}.sha256"
BASE="https://github.com/CypherTroopers/tar/releases/download/v0-263866"

cd "$CY_DIR"
if [ ! -f ./genesis.json ]; then
  echo "ERROR: genesis.json not found in $PWD"
  exit 1
fi

./build/bin/cypher --datadir "$DATADIR" init ./genesis.json

mkdir -p "$DEST"
cd "$DEST"

rm -rf chaindata
rm -f "$TAR" "$SHA"

wget -q -O "$TAR" "${BASE}/${TAR}"
wget -q -O "$SHA" "${BASE}/${SHA}"
sha256sum -c "$SHA"

tar -I zstd -xvf "$TAR"

test -d "$DEST/chaindata/ancient" || { echo "ERROR: ancient missing"; exit 1; }
echo "OK: installed $DEST/chaindata"

cat <<'EOT' > "$CY_DIR/start-cypher.sh"
#!/bin/bash
set -euo pipefail

CY_DIR="/root/go/src/github.com/cypherium/cypher"
cd "$CY_DIR"

EXTIP="$(curl -4 -s ifconfig.io || true)"

exec ./build/bin/cypher \
  --verbosity 4 \
  --rnetport 7100 \
  --syncmode full \
  ${EXTIP:+--nat extip:${EXTIP}} \
  --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.origins "*" \
  --rpc.gascap 10000000 --rpc.txfeecap 1000 \
  --http --http.addr 0.0.0.0 --http.port 8000 \
  --http.api eth,web3,net,txpool --http.corsdomain "*" \
  --port 6000 \
  --datadir chaindbname \
  --networkid 16166 \
  --gcmode archive \
  --bootnodes enode://a1e825dcb84155d5ec651a0cf98e22ac5d4dc34733d22eb6d031216ac2988646f0f85035118ec8e2369dace00221ed3a06a6aeacda520414e71f3b56662d7055@34.106.3.238:30301 \
  console
EOT

chmod +x "$CY_DIR/start-cypher.sh"

pm2 start "$CY_DIR/start-cypher.sh" --name cypher-node
pm2 save

pm2 startup systemd -u root --hp /root
pm2 save
