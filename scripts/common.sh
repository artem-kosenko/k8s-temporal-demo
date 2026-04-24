#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

COLIMA_PROFILE="${COLIMA_PROFILE:-temporal-demo}"
COLIMA_CPUS="${COLIMA_CPUS:-4}"
COLIMA_MEMORY="${COLIMA_MEMORY:-8}"
COLIMA_DISK="${COLIMA_DISK:-60}"
COLIMA_KUBERNETES_VERSION="${COLIMA_KUBERNETES_VERSION:-v1.35.0+k3s1}"

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

ensure_colima_context() {
  if kubectl config get-contexts -o name | rg -qx "colima-${COLIMA_PROFILE}"; then
    kubectl config use-context "colima-${COLIMA_PROFILE}" >/dev/null
    return 0
  fi

  if kubectl config get-contexts -o name | rg -qx "colima"; then
    kubectl config use-context colima >/dev/null
    return 0
  fi

  return 1
}

generate_colima_kubeconfig() {
  local kube_dir="${HOME}/.kube"
  local base_config="${kube_dir}/config"
  local generated_config="${kube_dir}/colima-${COLIMA_PROFILE}.yaml"
  local context_name="colima-${COLIMA_PROFILE}"
  local temp_source
  local temp_merged

  mkdir -p "${kube_dir}"
  temp_source="$(mktemp)"
  temp_merged="$(mktemp)"

  colima ssh --profile "${COLIMA_PROFILE}" -- sudo cat /etc/rancher/k3s/k3s.yaml > "${temp_source}"

  sed -i '' \
    -e "s/^  name: default$/  name: ${context_name}/" \
    -e "s/^    cluster: default$/    cluster: ${context_name}/" \
    -e "s/^    user: default$/    user: ${context_name}/" \
    -e "s/^current-context: default$/current-context: ${context_name}/" \
    "${temp_source}"

  cp "${temp_source}" "${generated_config}"

  if [[ -f "${base_config}" ]]; then
    KUBECONFIG="${base_config}:${generated_config}" kubectl config view --flatten > "${temp_merged}"
  else
    cp "${generated_config}" "${temp_merged}"
  fi

  mv "${temp_merged}" "${base_config}"
  rm -f "${temp_source}"

  kubectl config use-context "${context_name}" >/dev/null

  if [[ ! -f "${base_config}" ]]; then
    printf "Failed to generate kubeconfig at %s\n" "${base_config}" >&2
    return 1
  fi

  if ! kubectl config get-contexts -o name | rg -qx "${context_name}"; then
    printf "Failed to register kubectl context %s\n" "${context_name}" >&2
    return 1
  fi
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
