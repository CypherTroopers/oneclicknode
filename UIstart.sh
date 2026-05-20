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

if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)"

pyenv install -s 3.12.8
pyenv local 3.12.8

rm -rf .venv
python -m venv .venv
. .venv/bin/activate

python --version
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

curl -fsSL https://ollama.com/install.sh | sh
systemctl enable --now ollama
ollama pull qwen3.5:4b

pm2 delete CypherNode-chat 2>/dev/null || true

pm2 start ./.venv/bin/uvicorn \
  --name CypherNode-chat \
  --cwd "$PWD" \
  --interpreter none \
  -- app:app --host 0.0.0.0 --port 9600

pm2 save

echo "DONE"
