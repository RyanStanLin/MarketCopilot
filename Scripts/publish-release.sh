#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GH_TOKEN:?GitHub Actions token is required}"
: "${GITHUB_REPOSITORY:?Repository is required}"
: "${GITHUB_SHA:?Source commit is required}"
: "${MARKETCOPILOT_VERSION:?Release version is required}"
if [[ "${GITHUB_REF:-}" != refs/heads/main ]]; then
    printf '%s\n' 'Only main builds can publish a release.' >&2
    exit 1
fi

release_tag="v${MARKETCOPILOT_VERSION}"
release_notes="$(mktemp "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/MarketCopilot-release.XXXXXX")"
trap 'rm -f -- "$release_notes"' EXIT

shopt -s nullglob
release_assets=(dist/*.dmg dist/*.dmg.sha256)
if [[ ${#release_assets[@]} -ne 2 ]]; then
    printf '%s\n' 'Expected exactly one DMG and its SHA-256 file.' >&2
    exit 1
fi
(cd dist && sha256sum --check -- *.dmg.sha256)

# Refuse to attach a run's binaries to a tag for another source revision.
remote_tags="$(git ls-remote --tags origin "refs/tags/${release_tag}")"
tag_commit="${remote_tags%%$'\t'*}"
if [[ -n "$tag_commit" && "$tag_commit" != "$GITHUB_SHA" ]]; then
    printf '%s\n' 'The release tag already points to another commit.' >&2
    exit 1
fi

if release_id="$(gh api "repos/${GITHUB_REPOSITORY}/releases/tags/${release_tag}" --jq '.id' 2>/dev/null)"; then
    is_draft="$(gh api "repos/${GITHUB_REPOSITORY}/releases/${release_id}" --jq '.draft')"
    if [[ "$is_draft" == false ]]; then
        # A successful rerun keeps published assets intact, including immutable releases.
        gh release view "$release_tag" --repo "$GITHUB_REPOSITORY" --json url --jq '.url'
        exit 0
    fi
else
    python3 - <<'PY' > "$release_notes"
import os
print("macOS 27+ · Apple Silicon (arm64)\n")
print("Download the DMG and drag MarketCopilot to Applications.")
print("下载 DMG，将 MarketCopilot 拖入 Applications 即可安装。\n")
print("Built with local ad-hoc signing; Developer ID signing and notarization are not configured.\n")
print(f"Source commit: `{os.environ['GITHUB_SHA']}`")
print(f"Build: {os.environ['GITHUB_RUN_NUMBER']}")
PY
    gh release create "$release_tag" --repo "$GITHUB_REPOSITORY" \
        --target "$GITHUB_SHA" --title "MarketCopilot ${MARKETCOPILOT_VERSION}" \
        --notes-file "$release_notes" --generate-notes --draft
    release_id="$(gh api "repos/${GITHUB_REPOSITORY}/releases/tags/${release_tag}" --jq '.id')"
fi

gh release upload "$release_tag" "${release_assets[@]}" --repo "$GITHUB_REPOSITORY" --clobber
# GitHub chooses Latest by date / semantic version even if builds finish out of order.
release_url="$(gh api --method PATCH "repos/${GITHUB_REPOSITORY}/releases/${release_id}" \
    -F draft=false -f make_latest=legacy --jq '.html_url')"
printf '%s\n' "$release_url"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '[Download MarketCopilot %s](%s)\n' "$MARKETCOPILOT_VERSION" "$release_url" >> "$GITHUB_STEP_SUMMARY"
fi
