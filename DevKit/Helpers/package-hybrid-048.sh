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
APP_NAME="$(basename "$UPSTREAM_APP")"
APP_EXECUTABLE="${APP_NAME%.app}"

EXPECTED_RELAXIN_VERSION="${EXPECTED_RELAXIN_VERSION:-0.4.8}"
EXPECTED_ENGINE_SHA256="${EXPECTED_ENGINE_SHA256:-da8d8f3a7737545763379b4408186cf3d105b7afc807bd76513edc3bba0b2279}"
EXPECTED_BASEBIN_SHA256="${EXPECTED_BASEBIN_SHA256:-d7bf0990222958adf2986a00a0af24a64814a71d7cf5f1e3eb509cf03efea9e6}"
EXPECTED_BASEBIN_TC_SHA256="${EXPECTED_BASEBIN_TC_SHA256:-d2f158a259839b72464df028f71102df63a1fb6dd1262400bad82018d6945432}"

fail() {
    echo "error: $*" >&2
    exit 65
}

for app in "$UI_APP" "$UPSTREAM_APP"; do
    [[ -d "$app" ]] || fail "app bundle does not exist: $app"
    [[ -f "$app/Info.plist" ]] || fail "app bundle has no Info.plist: $app"
    [[ -f "$app/$APP_EXECUTABLE" ]] || fail "app bundle has no $APP_EXECUTABLE executable: $app"
done
for app in "$UI_APP" "$UPSTREAM_APP"; do
    [[ ! -e "$app/_CodeSignature" && ! -e "$app/embedded.mobileprovision" ]] \
        || fail "app bundle contains distribution signing material: $app"
done
[[ -f "$ENTITLEMENTS" ]] || fail "entitlements do not exist: $ENTITLEMENTS"
[[ "$OUTPUT_TIPA" == *.tipa ]] || fail "output must use the .tipa extension: $OUTPUT_TIPA"
command -v ldid >/dev/null 2>&1 || fail "ldid is required"

bundle_value() {
    /usr/libexec/PlistBuddy -c "Print :$2" "$1/Info.plist" 2>/dev/null || true
}

UPSTREAM_IDENTIFIER="$(bundle_value "$UPSTREAM_APP" CFBundleIdentifier)"
UPSTREAM_VERSION="$(bundle_value "$UPSTREAM_APP" CFBundleShortVersionString)"
UI_IDENTIFIER="$(bundle_value "$UI_APP" CFBundleIdentifier)"
[[ "$UPSTREAM_IDENTIFIER" == "com.aapl.relaxin" ]] \
    || fail "unexpected upstream bundle identifier: $UPSTREAM_IDENTIFIER"
[[ "$UPSTREAM_VERSION" == "$EXPECTED_RELAXIN_VERSION" ]] \
    || fail "expected upstream Relaxin $EXPECTED_RELAXIN_VERSION, found: $UPSTREAM_VERSION"
[[ "$UI_IDENTIFIER" == "$UPSTREAM_IDENTIFIER" ]] \
    || fail "UI and upstream bundle identifiers differ"

ENGINE_RELATIVE="Frameworks/RelaxinEngine.framework/RelaxinEngine"
for relative_path in "$ENGINE_RELATIVE" basebin.tar basebin.tc; do
    [[ -f "$UPSTREAM_APP/$relative_path" ]] \
        || fail "upstream core is missing $relative_path"
done

sha256_file() {
    shasum -a 256 "$1" | awk '{ print tolower($1) }'
}

verify_pinned_file() {
    local relative_path="$1"
    local expected="$2"
    local actual
    actual="$(sha256_file "$UPSTREAM_APP/$relative_path")"
    if [[ "$actual" != "$expected" && "${ALLOW_UNVERIFIED_RELAXIN_CORE:-0}" != "1" ]]; then
        fail "$relative_path does not match the audited $EXPECTED_RELAXIN_VERSION core (got $actual)"
    fi
}

verify_pinned_file "$ENGINE_RELATIVE" "$EXPECTED_ENGINE_SHA256"
verify_pinned_file basebin.tar "$EXPECTED_BASEBIN_SHA256"
verify_pinned_file basebin.tc "$EXPECTED_BASEBIN_TC_SHA256"

if command -v nm >/dev/null 2>&1; then
    NM_OUTPUT="$(nm -gU "$UPSTREAM_APP/$ENGINE_RELATIVE")"
    grep -Fq '_RLXEngineManifestIDownloadEnabledKey' <<<"$NM_OUTPUT" \
        || fail "upstream engine has no iDownload manifest interface"
    grep -Fq '_OBJC_CLASS_$_RLXPostJailbreakController' <<<"$NM_OUTPUT" \
        || fail "upstream engine has no post-jailbreak controller"
fi

OUTPUT_NAME="$(basename "$OUTPUT_TIPA")"
OUTPUT_DIRECTORY="$(dirname "$OUTPUT_TIPA")"
mkdir -p "$OUTPUT_DIRECTORY"
OUTPUT_DIRECTORY="$(cd "$OUTPUT_DIRECTORY" && pwd -P)"
OUTPUT_TIPA="$OUTPUT_DIRECTORY/$OUTPUT_NAME"
WORK_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/relaxin-hybrid-${EXPECTED_RELAXIN_VERSION//./}.XXXXXX")"
HYBRID_APP="$WORK_DIRECTORY/Payload/$APP_NAME"
TEMPORARY_TIPA="$OUTPUT_DIRECTORY/.$OUTPUT_NAME.tmp.$$"
BEFORE_CORE="$WORK_DIRECTORY/core-before.sha256"
AFTER_CORE="$WORK_DIRECTORY/core-after.sha256"
trap 'rm -rf "$WORK_DIRECTORY"; rm -f "$TEMPORARY_TIPA"' EXIT

mkdir -p "$WORK_DIRECTORY/Payload"
/usr/bin/ditto "$UPSTREAM_APP" "$HYBRID_APP"

core_manifest() {
    local app="$1"
    (
        cd "$app"
        find . -type f -print0 \
            | while IFS= read -r -d '' path; do
                case "${path#./}" in
                    "$APP_EXECUTABLE"|Relaxin.debug.dylib|__preview.dylib|Assets.car|default.metallib|AppIcon*.png)
                        continue
                        ;;
                esac
                shasum -a 256 "$path"
            done \
            | LC_ALL=C sort
    )
}

core_manifest "$HYBRID_APP" >"$BEFORE_CORE"

# Replace only UI-owned artifacts. Info.plist, framework, BaseBin, bootstrap,
# offsets, packages and every other upstream file remain from the pinned core.
/usr/bin/ditto "$UI_APP/$APP_EXECUTABLE" "$HYBRID_APP/$APP_EXECUTABLE"
chmod 0755 "$HYBRID_APP/$APP_EXECUTABLE"
for ui_resource in Assets.car default.metallib; do
    if [[ -f "$UI_APP/$ui_resource" ]]; then
        /usr/bin/ditto "$UI_APP/$ui_resource" "$HYBRID_APP/$ui_resource"
    fi
done
for ui_binary in Relaxin.debug.dylib __preview.dylib; do
    if [[ -f "$UI_APP/$ui_binary" ]]; then
        /usr/bin/ditto "$UI_APP/$ui_binary" "$HYBRID_APP/$ui_binary"
        chmod 0755 "$HYBRID_APP/$ui_binary"
    fi
done

find "$HYBRID_APP" -maxdepth 1 -type f -name 'AppIcon*.png' -delete
while IFS= read -r -d '' icon; do
    /usr/bin/ditto "$icon" "$HYBRID_APP/$(basename "$icon")"
done < <(find "$UI_APP" -maxdepth 1 -type f -name 'AppIcon*.png' -print0)

core_manifest "$HYBRID_APP" >"$AFTER_CORE"
cmp -s "$BEFORE_CORE" "$AFTER_CORE" \
    || fail "a non-UI upstream file changed while assembling the hybrid app"

if command -v otool >/dev/null 2>&1; then
    otool -L "$HYBRID_APP/$APP_EXECUTABLE" \
        | grep -Fq '@rpath/RelaxinEngine.framework/RelaxinEngine' \
        || fail "UI executable is not linked to RelaxinEngine.framework"
fi

ldid -S"$ENTITLEMENTS" -Cadhoc "$HYBRID_APP/$APP_EXECUTABLE"

PACKAGED_ENTITLEMENTS="$WORK_DIRECTORY/packaged-entitlements.plist"
ldid -e "$HYBRID_APP/$APP_EXECUTABLE" >"$PACKAGED_ENTITLEMENTS"
for entitlement in \
    "platform-application" \
    "proc_info-allow" \
    "com.apple.private.security.no-sandbox" \
    "com.apple.security.network.client" \
    "com.apple.developer.kernel.extended-virtual-addressing" \
    "com.apple.developer.kernel.increased-memory-limit"; do
    [[ "$(/usr/libexec/PlistBuddy -c "Print :$entitlement" \
        "$PACKAGED_ENTITLEMENTS" 2>/dev/null)" == "true" ]] \
        || fail "packaged executable is missing entitlement: $entitlement"
done

(
    cd "$WORK_DIRECTORY"
    COPYFILE_DISABLE=1 /usr/bin/ditto -c -k \
        --norsrc --noextattr --noqtn --noacl \
        --keepParent Payload "$TEMPORARY_TIPA"
)

/usr/bin/unzip -tq "$TEMPORARY_TIPA"
ARCHIVE_MEMBERS="$(/usr/bin/unzip -Z1 "$TEMPORARY_TIPA")"
for member in \
    "Payload/$APP_NAME/Info.plist" \
    "Payload/$APP_NAME/$APP_EXECUTABLE" \
    "Payload/$APP_NAME/$ENGINE_RELATIVE" \
    "Payload/$APP_NAME/basebin.tar"; do
    grep -Fxq "$member" <<<"$ARCHIVE_MEMBERS" \
        || fail "TIPA is missing $member"
done
if grep -Eq "^Payload/$APP_NAME/(_CodeSignature/|embedded[.]mobileprovision$)" \
    <<<"$ARCHIVE_MEMBERS"; then
    fail "TIPA contains distribution signing material"
fi
mv -f "$TEMPORARY_TIPA" "$OUTPUT_TIPA"

echo "Packaged Relaxin $EXPECTED_RELAXIN_VERSION core with custom UI: $OUTPUT_TIPA"
echo "Pinned upstream core preserved:"
echo "  RelaxinEngine $EXPECTED_ENGINE_SHA256"
echo "  basebin.tar   $EXPECTED_BASEBIN_SHA256"
echo "  basebin.tc    $EXPECTED_BASEBIN_TC_SHA256"
shasum -a 256 "$OUTPUT_TIPA"
