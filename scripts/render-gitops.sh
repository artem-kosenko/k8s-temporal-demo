#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

if ! REPO_URL="$(detect_gitops_repo_url)"; then
  printf "Set GITOPS_REPO_URL in %s before rendering GitOps manifests.\n" "${ENV_FILE}" >&2
  exit 1
fi

log "Rendering GitOps app manifests with repo ${REPO_URL} and revision ${GITOPS_REVISION}"

for file in \
  "${ROOT_DIR}/gitops/root/platform-app.yaml" \
  "${ROOT_DIR}/gitops/root/team-environments-appset.yaml"; do
  tmp_file="$(mktemp)"
  sed \
    -e "s#__REPO_URL__#${REPO_URL}#g" \
    -e "s#__TARGET_REVISION__#${GITOPS_REVISION}#g" \
    "${file}" > "${tmp_file}"
  mv "${tmp_file}" "${file}"
done

log "Rendered GitOps manifests in gitops/apps/"
