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

cd "$CY_DIR"

if [ ! -f ./genesistest.json ]; then
  echo "ERROR: genesistest.json not found in $PWD"
  exit 1
fi

./build/bin/cypher --datadir "$DATADIR" init ./genesistest.json

cat <<'EOT' > "$CY_DIR/start-cypher.sh"
#!/bin/bash
set -euo pipefail

CY_DIR="/root/go/src/github.com/cypherium/cypher"
cd "$CY_DIR"

exec ./build/bin/cypher \
  --verbosity 4 \
  --rnetport 7200 \
  --syncmode full \
  --nat extip:$(curl -4 -s ifconfig.io) \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port 9251 \
  --ws.origins "*" \
  --metrics \
  --http \
  --http.addr 0.0.0.0 \
  --http.port 8000 \
  --http.api eth,web3,net,txpool \
  --http.corsdomain "*" \
  --port 6000 \
  --datadir chaindbname \
  --networkid 123678 \
  --gcmode archive \
  --bootnodes enode://e10a90e9c7d077002d4d56b88943b8dfbca1d6490bb92c8202e6acb68ef23b521bf187fb40c07eed2f453f3782e8c53ca5a4ec1d34a4454960143501df8c4b95@149.102.156.210:6000 \
  console
EOT

chmod +x "$CY_DIR/start-cypher.sh"

echo "Starting node with pm2..."
pm2 start "$CY_DIR/start-cypher.sh" --name cypher-node

pm2 save
pm2 startup systemd -u root --hp /root
pm2 save

echo "DONE"
