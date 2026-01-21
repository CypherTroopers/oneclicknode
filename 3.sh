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

cd "$GOPATH/src/github.com/cypherium/cypher"
if [ ! -f ./genesis.json ]; then
  echo "ERROR: genesis.json not found in $PWD"
  exit 1
fi

./build/bin/cypher --datadir chaindbname init ./genesis.json

cd "$GOPATH/src/github.com/cypherium"
if [ ! -d cypher-bin/.git ]; then
  git clone https://github.com/cypherium/cypher-bin.git
fi

rm -rf "$GOPATH/src/github.com/cypherium/cypher/chaindbname/cypher/chaindata"
rsync -a cypher-bin/database/chaindb/cypher/chaindata/ cypher/chaindbname/cypher/chaindata/
cd "$GOPATH/src/github.com/cypherium/cypher"

cat <<'EOT' > start-cypher.sh
#!/bin/bash
set -euo pipefail
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
chmod +x start-cypher.sh
pm2 start ./start-cypher.sh --name cypher-node
pm2 save

STARTUP_LINE="$(pm2 startup systemd -u root --hp /root | sed -n 's/^.*\(pm2 startup.*\)$/\1/p' | head -n 1 || true)"
if [ -n "$STARTUP_LINE" ]; then
  bash -lc "$STARTUP_LINE"
fi
pm2 save
