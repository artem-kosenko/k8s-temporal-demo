#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin kubectl

printf "Argo CD UI: https://localhost:8080\n"
printf "Temporal UI: http://localhost:8233\n"
printf "Use Ctrl+C to stop both forwards.\n"

kubectl port-forward -n "${ARGOCD_NAMESPACE}" svc/argocd-server 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
PF_ARGO_PID=$!
kubectl port-forward -n "${TEMPORAL_NAMESPACE}" svc/temporal-web 8233:8080 >/tmp/temporal-port-forward.log 2>&1 &
PF_TEMPORAL_PID=$!

cleanup() {
  kill "${PF_ARGO_PID}" "${PF_TEMPORAL_PID}" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM
wait

