#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

export EXPECTED_RELAXIN_VERSION="0.5.2"
export EXPECTED_ENGINE_SHA256="06c2d9f0244afb8a7d6ce1db83682eccdb885c294d85e63e651db6d73d81e9b3"
export EXPECTED_BASEBIN_SHA256="a6a2eb13a1e533e19c382b9cab4e63b840d40d7d0fa79ca9380a1372161e01fe"
export EXPECTED_BASEBIN_TC_SHA256="f1617b9138169dff9ec1375d417043ae6dadb7e27e087d38fdf2b670959719b1"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-048.sh" "$@"
