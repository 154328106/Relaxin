#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

export EXPECTED_RELAXIN_VERSION="0.5.1"
export EXPECTED_ENGINE_SHA256="ca01578c1a26f27092d78a52eec8a8149bfb5d13117411a9c2ea98d513124728"
export EXPECTED_BASEBIN_SHA256="7533bef8064d8ac5d15e0c68bbf044e7beee39ef62d0ea2548ab7166f7c48b6e"
export EXPECTED_BASEBIN_TC_SHA256="eb24b8d9c5a6ca3e785ae5a05662d7c14800c6b0dfa475d3ad3d12c93f291bd7"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-048.sh" "$@"
