#!/usr/bin/env bash

set -euo pipefail

scripts=(settings.sh makecypher.sh start.sh UIstart.sh mining.sh)
base_url="${CYPHERSTART_BASE_URL:-https://raw.githubusercontent.com/CypherTroopers/oneclicknode/main}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$script_dir" == /dev/fd* ]] || [[ ! -w "$script_dir" ]]; then
  script_dir="${CYPHERSTART_TMP_DIR:-/tmp/cypherstart}"
  mkdir -p "$script_dir"
fi

download_script() {
  local script="$1"
  local destination="$2"  
  local url="${base_url}/${script}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$destination"
  elif command -v wget >/dev/null 2>&1; then
  wget -qO "$destination" "$url"
  else
    echo "error: curl or wget is required to download $script" >&2
    return 1
  fi
  chmod +x "$destination"
  }

ensure_go_path() {
  if ! command -v go >/dev/null 2>&1; then
    if [ -x /usr/local/go/bin/go ]; then
      export PATH="/usr/local/go/bin:$PATH"
    fi
  fi
}

for script in "${scripts[@]}"; do
  script_path="${script_dir}/${script}"
  if [[ ! -f "$script_path" ]]; then
  echo "info: $script not found, downloading from $base_url" >&2
    download_script "$script" "$script_path"
    fi

    ensure_go_path
    bash "$script_path"
    status=$?
  if [[ $status -ne 0 ]]; then
    echo "error: $script failed with exit code $status" >&2
    exit $status
  fi
done
