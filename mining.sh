#!/bin/bash
set -euo pipefail

cd /root

cat > mining-setup.sh <<'EOT'
#!/bin/bash
set -euo pipefail

if ! command -v go >/dev/null 2>&1; then
  if [ -x /usr/local/go/bin/go ]; then
    export PATH="/usr/local/go/bin:$PATH"
  fi
fi

# Resolve GOPATH safely
GOPATH="${GOPATH:-$(go env GOPATH 2>/dev/null || true)}"
if [[ -z "${GOPATH}" ]]; then
  GOPATH="/root/go"
fi

CY_DIR="$GOPATH/src/github.com/cypherium/cypher"
IPC="$CY_DIR/chaindbname/cypher.ipc"

if [[ ! -d "$CY_DIR" ]]; then
  echo "[ERR] cypher dir not found: $CY_DIR"
  exit 1
fi

if [[ ! -S "$IPC" ]]; then
  echo "[ERR] IPC not found: $IPC"
  echo "      Node running? pm2 status"
  echo "      Datadir matches? start-cypher.sh: --datadir chaindbname"
  exit 1
fi

cd "$CY_DIR"

read -rsp "Set NEW account password: " PASS; echo
read -rp  "Etherbase address (blank = use new account): " EBASE

# 1) Create new account (Ed25519)
ADDR_RAW="$(./build/bin/cypher attach "ipc:${IPC}" --exec "personal.newAccountEd25519(\"${PASS}\")" 2>&1 || true)"

# sanitize output safely (remove quotes + spaces + newlines)
ADDR="$(printf "%s" "$ADDR_RAW" | sed -E 's/^"|"$//g' | tr -d '[:space:]')"

if [[ -z "$ADDR" ]] || [[ "$ADDR" == *"error"* ]] || [[ "$ADDR" == *"Error"* ]]; then
  echo "[ERR] Failed to create account."
  echo "Output:"
  echo "$ADDR_RAW"
  exit 1
fi

echo "[OK] New account: $ADDR"

# 2) Start mining (your node's custom signature)
OUT_START="$(./build/bin/cypher attach "ipc:${IPC}" --exec "miner.start(1, \"${ADDR}\", \"${PASS}\")" 2>&1 || true)"
echo "[OK] miner.start issued"
echo "$OUT_START" | sed -E 's/^/[cypher] /'

# 3) Set etherbase (if blank, set to new account)
if [[ -z "$EBASE" ]]; then
  EBASE="$ADDR"
fi

OUT_EB="$(./build/bin/cypher attach "ipc:${IPC}" --exec "miner.setEtherbase(\"${EBASE}\")" 2>&1 || true)"
echo "[OK] miner.setEtherbase issued: $EBASE"
echo "$OUT_EB" | sed -E 's/^/[cypher] /'

echo
echo "Verify:"
echo "  ./build/bin/cypher attach ipc:${IPC}"
echo "  > eth.coinbase"
echo "  > miner.hashrate"
EOT

chmod +x mining-setup.sh

./mining-setup.sh

