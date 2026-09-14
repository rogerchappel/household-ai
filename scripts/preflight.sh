#!/usr/bin/env bash
set -euo pipefail

required=(bash git python3 ssh)
optional=(curl docker jq rg zstd)
missing_required=()

check_command() {
  local kind=$1
  local command=$2
  if command -v "$command" >/dev/null 2>&1; then
    printf 'PASS  %-9s %s\n' "$kind" "$command"
  else
    printf 'MISS  %-9s %s\n' "$kind" "$command"
    if [[ $kind == required ]]; then
      missing_required+=("$command")
    fi
  fi
}

echo "Household AI read-only preflight"
echo

for command in "${required[@]}"; do
  check_command required "$command"
done
for command in "${optional[@]}"; do
  check_command optional "$command"
done

echo
kernel=$(uname -s)
machine=$(uname -m)
case "$kernel:$machine" in
  Darwin:arm64)
    echo "PLATFORM  Apple Silicon macOS: verified runtime family"
    ;;
  Linux:x86_64)
    if [[ -r /etc/os-release ]] && rg -q '^ID=ubuntu$' /etc/os-release 2>/dev/null; then
      echo "PLATFORM  Ubuntu x86_64: verified runtime family"
    else
      echo "PLATFORM  Linux x86_64: expected or experimental; verify the support matrix"
    fi
    ;;
  *)
    echo "PLATFORM  $kernel $machine: unsupported for v0.1 inference"
    ;;
esac

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    echo "PASS      Docker Compose plugin"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "PASS      standalone docker-compose"
  else
    echo "MISS      optional Docker Compose"
  fi
fi

echo
if ((${#missing_required[@]})); then
  printf 'Preflight failed; install required commands: %s\n' "${missing_required[*]}" >&2
  exit 1
fi

echo "Required local commands are available."
echo "Optional misses are needed only by their related benchmark or deployment stage."
