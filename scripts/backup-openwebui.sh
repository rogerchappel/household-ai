#!/usr/bin/env bash
set -euo pipefail

umask 077

usage() {
  cat <<'EOF'
Usage: backup-openwebui.sh --execute ABSOLUTE_BACKUP_ROOT

Stops Open WebUI briefly and archives its persistent Docker volume. The backup
contains private household data and must be stored on encrypted media.
EOF
}

if [[ $# -ne 2 || $1 != --execute ]]; then
  usage >&2
  exit 2
fi

backup_root=$2
if [[ $backup_root != /* || $backup_root == / ]]; then
  echo "backup root must be an explicit absolute directory other than /" >&2
  exit 2
fi

for command in docker zstd; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "required command is unavailable: $command" >&2
    exit 1
  fi
done

container=${HOUSEHOLD_WEBUI_CONTAINER:-household-ai-web}
volume=${HOUSEHOLD_WEBUI_VOLUME:-household-ai-webui-data}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="$backup_root/openwebui-$timestamp"

docker inspect "$container" >/dev/null
docker volume inspect "$volume" >/dev/null
image_id=$(docker inspect "$container" --format '{{.Image}}')
image_name=$(docker inspect "$container" --format '{{.Config.Image}}')
was_running=$(docker inspect "$container" --format '{{.State.Running}}')

install -d -m 700 "$backup_dir"
printf 'container=%s\nvolume=%s\nimage=%s\nimage_id=%s\n' \
  "$container" "$volume" "$image_name" "$image_id" \
  >"$backup_dir/runtime.txt"

restart_container() {
  if [[ $was_running == true ]]; then
    docker start "$container" >/dev/null || true
  fi
}
trap restart_container EXIT

if [[ $was_running == true ]]; then
  docker stop --time 30 "$container" >/dev/null
fi

docker run --rm --network none --read-only \
  --mount "type=volume,src=$volume,dst=/data,readonly" \
  --entrypoint /bin/tar "$image_id" -C /data -cf - . \
  | zstd -T0 -3 -q -o "$backup_dir/openwebui-volume.tar.zst"

zstd -t "$backup_dir/openwebui-volume.tar.zst"
zstd -dc "$backup_dir/openwebui-volume.tar.zst" \
  | tar -tf - >"$backup_dir/volume-files.txt"
if ! grep -Eq '^\./webui\.db$|^webui\.db$' "$backup_dir/volume-files.txt"; then
  echo "backup does not contain the expected Open WebUI database" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$backup_dir/openwebui-volume.tar.zst" \
    >"$backup_dir/SHA256SUMS"
else
  shasum -a 256 "$backup_dir/openwebui-volume.tar.zst" \
    >"$backup_dir/SHA256SUMS"
fi
chmod 600 "$backup_dir"/*

restart_container
trap - EXIT

echo "backup verified: $backup_dir"
echo "copy it to separate encrypted storage and rehearse restoration"
