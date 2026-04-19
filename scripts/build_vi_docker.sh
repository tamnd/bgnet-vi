#!/usr/bin/env bash
# Convenience wrapper: build the guide inside the Dockerfile.vi image.
# Works with Podman or Docker; pass the binary via CONTAINER_BIN if needed.
# Usage: ./scripts/build_vi_docker.sh [tag]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TAG="${1:-bgnet-vi-build:local}"

if [[ -n "${CONTAINER_BIN:-}" ]]; then
    BIN="$CONTAINER_BIN"
elif command -v podman >/dev/null 2>&1; then
    BIN=podman
elif command -v docker >/dev/null 2>&1; then
    BIN=docker
else
    echo "Neither podman nor docker found. Install one, or set CONTAINER_BIN." >&2
    exit 1
fi

# Podman with SELinux needs the :Z flag; Docker tolerates it too on Linux
# but fails on macOS. Only add it on Linux.
MOUNT_FLAG=""
if [[ "$(uname -s)" == "Linux" ]]; then
    MOUNT_FLAG=":Z"
fi

echo "==> Using container engine: $BIN"
echo "==> Building image $TAG"
"$BIN" build -f Dockerfile.vi -t "$TAG" .

echo "==> Running build inside container"
"$BIN" run --rm \
    -v "$ROOT:/guide$MOUNT_FLAG" \
    -w /guide \
    "$TAG" \
    bash scripts/build_vi.sh

echo "==> Built docs/ on host:"
ls -la docs/
