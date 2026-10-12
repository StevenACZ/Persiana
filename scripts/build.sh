#!/bin/bash
set -euo pipefail
cd -P "$(dirname "$0")/.."
distribution="${PERSIANA_DISTRIBUTION:-0}"
[[ "$distribution" == 0 || "$distribution" == 1 ]] || exit 64
# A .noindex folder keeps this copy out of Spotlight: only /Applications/Persiana.app can work.
output_dir="${PERSIANA_OUTPUT_DIR:-$PWD/build.noindex}"
if [[ "$distribution" == 1 && -z "${PERSIANA_OUTPUT_DIR:-}" ]]; then
    output_dir="$PWD/build.noindex/distribution"
fi
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd -P)"
output="$output_dir/Persiana.app"
ensure_build_closed() {
    for persiana_pid in $(pgrep -x Persiana || true); do
        if [[ "$(ps -p "$persiana_pid" -o comm=)" == "$output/Contents/MacOS/Persiana" ]]; then
            echo 'Quit the build copy of Persiana before rebuilding it.' >&2
            exit 75
        fi
    done
}
ensure_build_closed
export -n SDKROOT 2>/dev/null || true
unset SDKROOT
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
sdk_version="$(xcrun --sdk macosx --show-sdk-version)"
link_sdk=(-Xswiftc -Xclang-linker -Xswiftc -isysroot -Xswiftc -Xclang-linker -Xswiftc "$sdk_path")
swift build -c release --arch arm64 --product Persiana \
    -Xswiftc -file-prefix-map -Xswiftc "$PWD=." \
    -Xswiftc -gnone \
    "${link_sdk[@]}"
bin_dir="$(swift build -c release --arch arm64 --show-bin-path "${link_sdk[@]}")"
linked_sdk="$(otool -l "$bin_dir/Persiana" | awk '/cmd LC_BUILD_VERSION/ {found=1} found && $1 == "sdk" {print $2; exit}')"
if [[ "$linked_sdk" != "$sdk_version" ]]; then
    echo "Persiana links SDK $linked_sdk instead of $sdk_version; macOS would draw it without Liquid Glass." >&2
    exit 1
fi
bundle_stage="$(mktemp -d "$output_dir/.persiana-bundle.XXXXXX")"
trap 'rm -rf "$bundle_stage"' EXIT
bundle="$bundle_stage/Persiana.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources/Licenses"
cp "$bin_dir/Persiana" "$bundle/Contents/MacOS/Persiana"
cp Assets/Info.plist "$bundle/Contents/Info.plist"
if [[ -f Assets/AppIcon.icns ]]; then cp Assets/AppIcon.icns "$bundle/Contents/Resources/AppIcon.icns"; fi
cp LICENSE THIRD_PARTY_NOTICES.md "$bundle/Contents/Resources/Licenses/"
plist="$bundle/Contents/Info.plist"
if [[ -n "${APP_VERSION:-}" ]]; then
    [[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 64
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$plist"
fi
if [[ -n "${APP_BUILD:-}" ]]; then
    [[ "$APP_BUILD" =~ ^[1-9][0-9]*$ ]] || exit 64
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD" "$plist"
fi
binary="$bundle/Contents/MacOS/Persiana"
while IFS= read -r rpath; do
    if [[ "$rpath" == /* ]]; then install_name_tool -delete_rpath "$rpath" "$binary"; fi
done < <(otool -l "$binary" | awk '/cmd LC_RPATH/ {getline; getline; sub(/^ *path /, ""); sub(/ \(offset.*$/, ""); print}')
strip -S "$binary"
scripts/sign-bundle.sh "$bundle"
ensure_build_closed
if [[ -e "$output" ]]; then mv "$output" "$bundle_stage/previous.app"; fi
if ! mv "$bundle" "$output"; then
    if [[ -e "$bundle_stage/previous.app" ]]; then mv "$bundle_stage/previous.app" "$output"; fi
    exit 74
fi
echo "Built and verified: $output"
