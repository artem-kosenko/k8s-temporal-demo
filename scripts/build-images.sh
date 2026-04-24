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
  image_tar="$(mktemp -t "${worker}.XXXXXX.tar")"

  log "Building ${image_ref} with Docker"
  docker build \
    --platform linux/arm64 \
    --tag "${image_ref}" \
    --file "${ROOT_DIR}/build/docker/worker.Dockerfile" \
    --build-arg "WORKER_BINARY=${worker}" \
    "${ROOT_DIR}"

  log "Exporting ${image_ref}"
  docker save --output "${image_tar}" "${image_ref}"

  log "Importing ${image_ref} into Colima k3s/containerd"
  colima ssh --profile "${COLIMA_PROFILE}" -- sudo k3s ctr images import - < "${image_tar}"

  rm -f "${image_tar}"
done

log "Local worker images are ready"
