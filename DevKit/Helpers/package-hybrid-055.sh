#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

export EXPECTED_RELAXIN_VERSION="0.5.5"
export EXPECTED_ENGINE_SHA256="b9effa3d7fa9f34755bc58c986284c3d74f9f746acf606a7f7c1a9eedea710ca"
export EXPECTED_BASEBIN_SHA256="8ab5171e36fa30ca66b58839c2e6e67e5b2dbf56cb327c8084650eff12e30307"
export EXPECTED_BASEBIN_TC_SHA256="c35a1df635c0e232aa29f36de1ce905a343087ee2c2981a572de607c14cb0f3e"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-048.sh" "$@"
