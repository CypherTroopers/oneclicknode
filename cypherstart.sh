#!/usr/bin/env bash

set -euo pipefail

scripts=(1.sh 2.sh 3.sh 4.sh 5.sh)
base_url="${CYPHERSTART_BASE_URL:-https://raw.githubusercontent.com/CypherTroopers/test2/main}"

download_script() {
  local script="$1"
  local url="${base_url}/${script}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$script"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$script" "$url"
  else
    echo "error: curl or wget is required to download $script" >&2
    return 1
  fi
  chmod +x "$script"
}

ensure_go_path() {
  if ! command -v go >/dev/null 2>&1; then
    if [ -x /usr/local/go/bin/go ]; then
      export PATH="/usr/local/go/bin:$PATH"
    fi
  fi
}

for script in "${scripts[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "info: $script not found, downloading from $base_url" >&2
    download_script "$script"
  fi

    ensure_go_path
    bash "$script"
  status=$?
  if [[ $status -ne 0 ]]; then
    echo "error: $script failed with exit code $status" >&2
    exit $status
  fi
done
