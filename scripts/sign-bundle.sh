#!/bin/bash
set -euo pipefail
bundle="${1:?Usage: sign-bundle.sh APP}"
distribution="${PERSIANA_DISTRIBUTION:-0}"
[[ "$distribution" == 0 || "$distribution" == 1 ]] || exit 64
if [[ "$distribution" == 1 ]]; then authority='Developer ID Application'; else authority='Apple Development'; fi
identity="${PERSIANA_SIGN_IDENTITY:-}"
if [[ -z "$identity" ]]; then
    identities=()
    while IFS= read -r candidate; do identities+=("$candidate"); done < <(
        security find-identity -v -p codesigning | awk -F '"' -v kind="$authority" 'index($2, kind ":") == 1 {print $2}'
    )
    [[ ${#identities[@]} == 1 ]] || {
        echo "Expected one $authority identity; set PERSIANA_SIGN_IDENTITY explicitly." >&2; exit 65;
    }
    identity="${identities[0]}"
fi
flags=(--force --options runtime --sign "$identity")
if [[ "$distribution" == 1 ]]; then flags+=(--timestamp); else flags+=(--timestamp=none); fi
codesign "${flags[@]}" "$bundle"
codesign --verify --deep --strict "$bundle"
codesign -dvv "$bundle" 2>&1 | awk -v kind="$authority" 'index($0, "Authority=" kind ":") == 1 {found=1} END {exit !found}'
