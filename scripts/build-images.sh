#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin minikube

declare -a workers=(
  "team-a-worker"
  "team-b-worker"
)

for worker in "${workers[@]}"; do
  image_ref="${IMAGE_REGISTRY_PREFIX}/${worker}:${LOCAL_IMAGE_TAG}"
  log "Building ${image_ref} into Minikube"
  minikube image build \
    --profile="${MINIKUBE_PROFILE}" \
    --tag "${image_ref}" \
    --file "${ROOT_DIR}/build/docker/worker.Dockerfile" \
    --build-opt "build-arg=WORKER_BINARY=${worker}" \
    "${ROOT_DIR}"
done

log "Local worker images are ready"
