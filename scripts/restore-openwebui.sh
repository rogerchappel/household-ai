#!/usr/bin/env bash
set -euo pipefail

umask 077

usage() {
  cat <<'EOF'
Usage: restore-openwebui.sh --execute ABSOLUTE_ARCHIVE NEW_VOLUME [HELPER_IMAGE]

Restores an Open WebUI archive into a new Docker volume. It refuses an existing
volume and never switches the production deployment automatically.
EOF
}

if [[ $# -lt 3 || $# -gt 4 || $1 != --execute ]]; then
  usage >&2
  exit 2
fi

archive=$2
new_volume=$3
helper_image=${4-}

if [[ $archive != /* || ! -f $archive ]]; then
  echo "archive must be an existing absolute file" >&2
  exit 2
fi
if [[ ! $new_volume =~ ^[A-Za-z0-9][A-Za-z0-9_.-]+$ ]]; then
  echo "new volume name contains unsupported characters" >&2
  exit 2
fi

for command in docker zstd; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "required command is unavailable: $command" >&2
    exit 1
  fi
done

if docker volume inspect "$new_volume" >/dev/null 2>&1; then
  echo "refusing to overwrite existing volume: $new_volume" >&2
  exit 1
fi

zstd -t "$archive"
if ! zstd -dc "$archive" | tar -tf - \
  | grep -E '^\./webui\.db$|^webui\.db$' >/dev/null; then
  echo "archive does not contain the expected Open WebUI database" >&2
  exit 1
fi

if [[ -z $helper_image ]]; then
  container=${HOUSEHOLD_WEBUI_CONTAINER:-household-ai-web}
  if ! helper_image=$(docker inspect "$container" --format '{{.Image}}' 2>/dev/null); then
    echo "supply a locally available helper image as the fourth argument" >&2
    exit 1
  fi
fi
docker image inspect "$helper_image" >/dev/null

created=false
remove_incomplete_volume() {
  if [[ $created == true ]]; then
    docker volume rm "$new_volume" >/dev/null || true
  fi
}
trap remove_incomplete_volume EXIT

docker volume create "$new_volume" >/dev/null
created=true
zstd -dc "$archive" \
  | docker run --rm -i --network none \
      --mount "type=volume,src=$new_volume,dst=/restore" \
      --entrypoint /bin/tar "$helper_image" -C /restore -xf -

docker run --rm --network none --read-only \
  --mount "type=volume,src=$new_volume,dst=/restore,readonly" \
  --entrypoint /bin/sh "$helper_image" -c 'test -f /restore/webui.db'

created=false
trap - EXIT

echo "isolated restore created: $new_volume"
echo "inspect it with a temporary Open WebUI container before any cutover"
