#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin colima
require_bin kubectl
require_bin docker
require_bin rg

if ! docker info >/dev/null 2>&1; then
  log "Docker is not reachable yet; Colima will provide the Docker runtime"
fi

log "Starting Colima profile ${COLIMA_PROFILE} with Kubernetes enabled"
colima start \
  --profile "${COLIMA_PROFILE}" \
  --runtime docker \
  --kubernetes \
  --cpus "${COLIMA_CPUS}" \
  --memory "${COLIMA_MEMORY}" \
  --disk "${COLIMA_DISK}" \
  --kubernetes-version "${COLIMA_KUBERNETES_VERSION}"

if ! docker info >/dev/null 2>&1; then
  printf "Docker is still not reachable after Colima start.\n" >&2
  exit 1
fi

log "Generating kubeconfig for Colima profile ${COLIMA_PROFILE}"
generate_colima_kubeconfig

if ensure_colima_context; then
  log "Using kubectl context $(kubectl config current-context)"
else
  printf "Colima started but kubectl context selection failed.\n" >&2
  exit 1
fi

log "Waiting for Kubernetes API readiness"
kubectl wait --for=condition=Ready nodes --all --timeout=5m

log "Cluster is ready"
