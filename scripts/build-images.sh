#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin colima
require_bin docker

if ! docker info >/dev/null 2>&1; then
  printf "Docker is not reachable. Start Colima first with ./scripts/start-cluster.sh.\n" >&2
  exit 1
fi

declare -a workers=(
  "team-a-worker"
  "team-b-worker"
)

for worker in "${workers[@]}"; do
  image_ref="${IMAGE_REGISTRY_PREFIX}/${worker}:${LOCAL_IMAGE_TAG}"

  log "Building ${image_ref} with Docker in the active Colima runtime"
  docker build \
    --platform linux/arm64 \
    --tag "${image_ref}" \
    --file "${ROOT_DIR}/build/docker/worker.Dockerfile" \
    --build-arg "WORKER_BINARY=${worker}" \
    "${ROOT_DIR}"

  docker image inspect "${image_ref}" >/dev/null
done

log "Local worker images are ready"
