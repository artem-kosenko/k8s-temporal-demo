#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin minikube
require_bin kubectl
require_bin docker

if ! docker info >/dev/null 2>&1; then
  printf "Docker is installed but not reachable. Start Docker Desktop or Colima first.\n" >&2
  exit 1
fi

log "Starting Minikube profile ${MINIKUBE_PROFILE}"
minikube start \
  --profile="${MINIKUBE_PROFILE}" \
  --driver="${MINIKUBE_DRIVER}" \
  --container-runtime=containerd \
  --cpus="${MINIKUBE_CPUS}" \
  --memory="${MINIKUBE_MEMORY}" \
  --kubernetes-version="${MINIKUBE_KUBERNETES_VERSION}"

log "Enabling ingress and metrics-server addons"
minikube addons enable ingress --profile="${MINIKUBE_PROFILE}"
minikube addons enable metrics-server --profile="${MINIKUBE_PROFILE}"

log "Switching kubectl context to ${MINIKUBE_PROFILE}"
kubectl config use-context "${MINIKUBE_PROFILE}" >/dev/null

log "Cluster is ready"

