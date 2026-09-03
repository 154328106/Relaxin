#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"

exec /bin/bash "$SCRIPT_DIRECTORY/package-hybrid-whitelist-050.sh" "$@"
