#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$#" -ne 4 ]]; then
    echo "usage: $0 <ui-app> <upstream-app> <entitlements> <output-tipa>" >&2
    exit 64
fi

UI_APP="$1"
UPSTREAM_APP="$2"
ENTITLEMENTS="$3"
OUTPUT_TIPA="$4"
SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd -P)"
COMMON_PACKAGER="$SCRIPT_DIRECTORY/package-hybrid-048.sh"

EXPECTED_ENGINE_SHA256="bf6417b851a7383a2117bed8d6559cdcd7d44543d5c54be83b971d4be9cdc499"
EXPECTED_BASEBIN_SHA256="a83d8139021a71c9c49656f6d5f57dd500500e9a6854f54c6c03f56b52a97eab"
EXPECTED_BASEBIN_TC_SHA256="79f2f0bc26181400e1fabdd091d51e1ded3ac335c32006eb21d5ad7c93feb603"
ENGINE_RELATIVE="Frameworks/RelaxinEngine.framework/RelaxinEngine"
WHITELIST_COMPONENTS=(libjailbreak.dylib launchdhook.dylib systemhook.dylib)

fail() {
    echo "error: $*" >&2
    exit 65
}

sha256_file() {
    shasum -a 256 "$1" | awk '{ print tolower($1) }'
}

verify_sha256() {
    local path="$1"
    local expected="$2"
    local actual
    [[ -f "$path" ]] || fail "required file is missing: $path"
    actual="$(sha256_file "$path")"
    [[ "$actual" == "$expected" ]] \
        || fail "unexpected upstream hash for $(basename "$path"): $actual"
}

for tool in gtar trustcache shasum rg; do
    command -v "$tool" >/dev/null 2>&1 || fail "$tool is required"
done
[[ -x "$COMMON_PACKAGER" || -f "$COMMON_PACKAGER" ]] \
    || fail "common hybrid packager is missing"
[[ -d "$UI_APP" && -d "$UPSTREAM_APP" ]] || fail "app bundle is missing"
[[ -f "$UI_APP/basebin.tar" ]] || fail "source UI app has no Whitelist BaseBin"

verify_sha256 "$UPSTREAM_APP/$ENGINE_RELATIVE" "$EXPECTED_ENGINE_SHA256"
verify_sha256 "$UPSTREAM_APP/basebin.tar" "$EXPECTED_BASEBIN_SHA256"
verify_sha256 "$UPSTREAM_APP/basebin.tc" "$EXPECTED_BASEBIN_TC_SHA256"

WORK_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/relaxin-whitelist-050.XXXXXX")"
STAGED_APP="$WORK_DIRECTORY/Relaxin.app"
UPSTREAM_BASEBIN="$WORK_DIRECTORY/upstream"
SOURCE_BASEBIN="$WORK_DIRECTORY/source"
BEFORE_MANIFEST="$WORK_DIRECTORY/basebin-before.sha256"
AFTER_MANIFEST="$WORK_DIRECTORY/basebin-after.sha256"
trap 'rm -rf "$WORK_DIRECTORY"' EXIT HUP INT TERM

/usr/bin/ditto "$UPSTREAM_APP" "$STAGED_APP"
mkdir -p "$UPSTREAM_BASEBIN" "$SOURCE_BASEBIN"
gtar -xf "$UPSTREAM_APP/basebin.tar" -C "$UPSTREAM_BASEBIN"
gtar -xf "$UI_APP/basebin.tar" -C "$SOURCE_BASEBIN"
[[ -d "$UPSTREAM_BASEBIN/basebin" && -d "$SOURCE_BASEBIN/basebin" ]] \
    || fail "invalid BaseBin archive layout"

preserved_manifest() {
    local root="$1"
    (
        cd "$root/basebin"
        find . -type f -print0 \
            | while IFS= read -r -d '' path; do
                case "${path#./}" in
                    .version|basebin.tc|libjailbreak.dylib|launchdhook.dylib|systemhook.dylib)
                        continue
                        ;;
                esac
                shasum -a 256 "$path"
            done \
            | LC_ALL=C sort
    )
}

preserved_manifest "$UPSTREAM_BASEBIN" >"$BEFORE_MANIFEST"
for component in "${WHITELIST_COMPONENTS[@]}"; do
    source_path="$SOURCE_BASEBIN/basebin/$component"
    [[ -f "$source_path" ]] || fail "Whitelist source BaseBin is missing $component"
    /usr/bin/ditto "$source_path" "$UPSTREAM_BASEBIN/basebin/$component"
    chmod 0755 "$UPSTREAM_BASEBIN/basebin/$component"
done

printf '%s\n' '0.5.0-whitelist.1' >"$UPSTREAM_BASEBIN/basebin/.version"
rm -f "$UPSTREAM_BASEBIN/basebin/basebin.tc"
trustcache create \
    -u 00000000-0000-0000-0000-000000000000 \
    "$UPSTREAM_BASEBIN/basebin/basebin.tc" \
    "$UPSTREAM_BASEBIN/basebin"

preserved_manifest "$UPSTREAM_BASEBIN" >"$AFTER_MANIFEST"
cmp -s "$BEFORE_MANIFEST" "$AFTER_MANIFEST" \
    || fail "a non-Whitelist upstream BaseBin component changed"

rg -a -q 'cn[.]zqbb[.]inject[.]plist' \
    "$UPSTREAM_BASEBIN/basebin/libjailbreak.dylib" \
    "$UPSTREAM_BASEBIN/basebin/launchdhook.dylib" \
    "$UPSTREAM_BASEBIN/basebin/systemhook.dylib" \
    || fail "patched BaseBin does not contain the Whitelist selection path"
rg -a -q 'cn[.]zqbb[.]inject[.]system[.]plist' \
    "$UPSTREAM_BASEBIN/basebin/launchdhook.dylib" \
    "$UPSTREAM_BASEBIN/basebin/systemhook.dylib" \
    || fail "patched BaseBin does not contain the system allowlist path"

/usr/bin/ditto "$UPSTREAM_BASEBIN/basebin/basebin.tc" "$STAGED_APP/basebin.tc"
rm -f "$STAGED_APP/basebin.tar"
ARCHIVE_EPOCH="${SOURCE_DATE_EPOCH:-1700000000}"
gtar \
    --sort=name \
    --mtime="@$ARCHIVE_EPOCH" \
    --clamp-mtime \
    --owner=0 \
    --group=0 \
    -cf "$STAGED_APP/basebin.tar" \
    -C "$UPSTREAM_BASEBIN" basebin

ALLOW_UNVERIFIED_RELAXIN_CORE=1 \
EXPECTED_RELAXIN_VERSION=0.5.0 \
EXPECTED_ENGINE_SHA256="$EXPECTED_ENGINE_SHA256" \
EXPECTED_BASEBIN_SHA256="$EXPECTED_BASEBIN_SHA256" \
EXPECTED_BASEBIN_TC_SHA256="$EXPECTED_BASEBIN_TC_SHA256" \
    /bin/bash "$COMMON_PACKAGER" \
        "$UI_APP" "$STAGED_APP" "$ENTITLEMENTS" "$OUTPUT_TIPA"

echo "Whitelist 0.5.0 hybrid audit:"
echo "  official RelaxinEngine preserved: $EXPECTED_ENGINE_SHA256"
echo "  BaseBin version: 0.5.0-whitelist.1"
echo "  BaseBin archive: $(sha256_file "$STAGED_APP/basebin.tar")"
echo "  BaseBin trust cache: $(sha256_file "$STAGED_APP/basebin.tc")"
