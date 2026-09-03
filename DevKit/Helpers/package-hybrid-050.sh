#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

export EXPECTED_RELAXIN_VERSION="0.5.0"
export EXPECTED_ENGINE_SHA256="bf6417b851a7383a2117bed8d6559cdcd7d44543d5c54be83b971d4be9cdc499"
export EXPECTED_BASEBIN_SHA256="a83d8139021a71c9c49656f6d5f57dd500500e9a6854f54c6c03f56b52a97eab"
export EXPECTED_BASEBIN_TC_SHA256="79f2f0bc26181400e1fabdd091d51e1ded3ac335c32006eb21d5ad7c93feb603"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-048.sh" "$@"
