#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin minikube

ACTION="${1:-stop}"

case "${ACTION}" in
  stop)
    log "Stopping Minikube profile ${MINIKUBE_PROFILE}"
    minikube stop --profile="${MINIKUBE_PROFILE}"
    ;;
  delete)
    log "Deleting Minikube profile ${MINIKUBE_PROFILE}"
    minikube delete --profile="${MINIKUBE_PROFILE}"
    ;;
  *)
    printf "Usage: %s [stop|delete]\n" "$0" >&2
    exit 1
    ;;
esac

