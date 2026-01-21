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
[ -d CypherNode-chat/.git ] || git clone https://github.com/CypherTroopers/CypherNode-chat.git
cd CypherNode-chat

python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

curl -fsSL https://ollama.com/install.sh | sh
systemctl enable --now ollama
ollama pull qwen2.5:3b

pm2 start ./.venv/bin/uvicorn \
  --name CypherNode-chat \
  --cwd "$PWD" \
  --interpreter none \
  -- app:app --host 0.0.0.0 --port 9600
pm2 save

echo "DONE"
