#!/bin/bash
set -euo pipefail
cd -P "$(dirname "$0")/.."
ensure_app_closed() {
    if pgrep -x Persiana >/dev/null; then
        echo 'Quit Persiana before installing an update.' >&2
        exit 75
    fi
}
ensure_app_closed
PERSIANA_DISTRIBUTION=0 PERSIANA_OUTPUT_DIR="$PWD/build" scripts/build.sh
bundle="$PWD/build/Persiana.app"
# macOS 27 hides Persiana's own menu bar icon when the app runs outside /Applications.
parent_dir="${PERSIANA_INSTALL_DIR:-/Applications}"
destination="$parent_dir/Persiana.app"
install_stage="$(mktemp -d "$parent_dir/.persiana-install.XXXXXX")"
completed=false
cleanup() {
    if [[ "$completed" == false && -e "$install_stage/previous.app" ]]; then
        if [[ -e "$destination" ]]; then rm -rf "$destination"; fi
        mv "$install_stage/previous.app" "$destination"
    fi
    rm -rf "$install_stage"
}
trap cleanup EXIT
ditto "$bundle" "$install_stage/Persiana.app"
codesign --verify --deep --strict "$install_stage/Persiana.app"
if [[ -e "$destination" ]]; then
    backup="$PWD/build/rollback-$(date +%Y%m%d-%H%M%S)-$(uuidgen | cut -c1-8).zip"
    ditto -c -k --norsrc --noextattr --keepParent "$destination" "$backup"
    ditto -x -k "$backup" "$install_stage/rollback-check"
    codesign --verify --deep --strict "$install_stage/rollback-check/Persiana.app"
    echo "Rollback: $backup"
fi
ensure_app_closed
if [[ -e "$destination" ]]; then
    mv "$destination" "$install_stage/previous.app"
fi
mv "$install_stage/Persiana.app" "$destination"
codesign --verify --deep --strict "$destination"
codesign -dvv "$destination" 2>&1 | awk '/Authority=Apple Development/ {found=1} END {exit !found}'
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
completed=true
echo "Installed: $destination"
