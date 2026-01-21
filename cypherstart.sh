#!/usr/bin/env bash

set -u

scripts=(1.sh 2.sh 3.sh 4.sh 5.sh)

for script in "${scripts[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "error: $script not found" >&2
    exit 1
  fi

  bash "$script"
  status=$?
  if [[ $status -ne 0 ]]; then
    echo "error: $script failed with exit code $status" >&2
    exit $status
  fi
done
