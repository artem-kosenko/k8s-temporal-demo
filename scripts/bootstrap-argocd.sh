#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin helm
require_bin kubectl
require_bin rg

if rg -q "__REPO_URL__|__TARGET_REVISION__" "${ROOT_DIR}/gitops/root"; then
  printf "GitOps manifests still contain placeholders. Run ./scripts/render-gitops.sh first.\n" >&2
  exit 1
fi

log "Installing or upgrading Argo CD in namespace ${ARGOCD_NAMESPACE}"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --namespace "${ARGOCD_NAMESPACE}" \
  --create-namespace \
  --version "${ARGOCD_CHART_VERSION}" \
  --values "${ROOT_DIR}/platform/bootstrap/argocd-values.yaml"

kubectl wait \
  --namespace "${ARGOCD_NAMESPACE}" \
  --for=condition=Available deployment/argocd-server \
  --timeout=10m

if ! REPO_URL="$(detect_gitops_repo_url)"; then
  log "Argo CD is installed, but GitOps repo URL is not configured"
  printf "Set GITOPS_REPO_URL in %s or add a git remote, then re-run this script.\n" "${ENV_FILE}" >&2
  exit 0
fi

log "Creating Argo CD root application from ${REPO_URL}"
sed \
  -e "s#__REPO_URL__#${REPO_URL}#g" \
  -e "s#__TARGET_REVISION__#${GITOPS_REVISION}#g" \
  -e "s#__ROOT_APP_NAME__#${ARGOCD_ROOT_APP_NAME}#g" \
  "${ROOT_DIR}/gitops/bootstrap/root-application.yaml.tmpl" | kubectl apply -f -

log "Root application is bootstrapped"
