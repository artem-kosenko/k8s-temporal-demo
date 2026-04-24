#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-temporal-demo}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-docker}"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-4}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-8192}"
MINIKUBE_KUBERNETES_VERSION="${MINIKUBE_KUBERNETES_VERSION:-stable}"

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_CHART_VERSION="${ARGOCD_CHART_VERSION:-9.5.4}"
ARGOCD_ROOT_APP_NAME="${ARGOCD_ROOT_APP_NAME:-platform-root}"
GITOPS_REVISION="${GITOPS_REVISION:-main}"

TEMPORAL_NAMESPACE="${TEMPORAL_NAMESPACE:-temporal-system}"
TEMPORAL_HELM_CHART_VERSION="${TEMPORAL_HELM_CHART_VERSION:-0.72.0}"
TEMPORAL_WORKER_CONTROLLER_CHART_VERSION="${TEMPORAL_WORKER_CONTROLLER_CHART_VERSION:-0.24.0}"

LOCAL_IMAGE_TAG="${LOCAL_IMAGE_TAG:-dev}"
IMAGE_REGISTRY_PREFIX="${IMAGE_REGISTRY_PREFIX:-local}"

require_bin() {
  local bin="$1"
  if ! command -v "${bin}" >/dev/null 2>&1; then
    printf "Missing required binary: %s\n" "${bin}" >&2
    exit 1
  fi
}

log() {
  printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"
}

detect_gitops_repo_url() {
  local raw_url

  if [[ -n "${GITOPS_REPO_URL:-}" ]]; then
    raw_url="${GITOPS_REPO_URL}"
  elif git -C "${ROOT_DIR}" config --get remote.origin.url >/dev/null 2>&1; then
    raw_url="$(git -C "${ROOT_DIR}" config --get remote.origin.url)"
  else
    return 1
  fi

  if [[ "${raw_url}" =~ ^git@([^:]+):(.+)$ ]]; then
    printf "https://%s/%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  if [[ "${raw_url}" =~ ^ssh://git@([^/]+)/(.+)$ ]]; then
    printf "https://%s/%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  printf "%s" "${raw_url}"
}
