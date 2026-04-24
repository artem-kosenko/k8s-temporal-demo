#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_bin colima

ACTION="${1:-stop}"

case "${ACTION}" in
  stop)
    log "Stopping Colima profile ${COLIMA_PROFILE}"
    colima stop --profile "${COLIMA_PROFILE}"
    ;;
  delete)
    log "Deleting Colima profile ${COLIMA_PROFILE}"
    colima delete --profile "${COLIMA_PROFILE}" --force
    ;;
  *)
    printf "Usage: %s [stop|delete]\n" "$0" >&2
    exit 1
    ;;
esac
