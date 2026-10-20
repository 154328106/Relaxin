#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

export EXPECTED_RELAXIN_VERSION="0.5.6"
export EXPECTED_ENGINE_SHA256="14ac96e4f47e8b3eac9a879e1aac7e0cee79a8bbdfeeb8362d043aa6e2ecfced"
export EXPECTED_BASEBIN_SHA256="06a70fec4e22ef85dd4cd2015cc4d6c2f5ceaddea03c0d8dc0d832b5dc7e6e95"
export EXPECTED_BASEBIN_TC_SHA256="73a34b052eff213c536eb8cc54d337cbda5260716b70e5ffb2d9208c51e98ce6"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-048.sh" "$@"
