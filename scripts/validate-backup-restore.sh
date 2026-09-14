#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_dir"

bash -n scripts/backup-openwebui.sh
bash -n scripts/restore-openwebui.sh

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if scripts/backup-openwebui.sh >"$tmp_dir/backup.out" 2>&1; then
  echo "backup unexpectedly ran without --execute" >&2
  exit 1
fi
if ! rg -q '^Usage: backup-openwebui\.sh --execute' "$tmp_dir/backup.out"; then
  echo "backup did not explain its execution gate" >&2
  exit 1
fi

if scripts/restore-openwebui.sh >"$tmp_dir/restore.out" 2>&1; then
  echo "restore unexpectedly ran without --execute" >&2
  exit 1
fi
if ! rg -q '^Usage: restore-openwebui\.sh --execute' "$tmp_dir/restore.out"; then
  echo "restore did not explain its execution gate" >&2
  exit 1
fi

rg -q -- '--mount "type=volume,src=\$volume,dst=/data,readonly"' \
  scripts/backup-openwebui.sh
rg -q 'refusing to overwrite existing volume' scripts/restore-openwebui.sh
rg -q 'never switches the production deployment automatically' \
  scripts/restore-openwebui.sh

echo "backup and restore validation passed"
