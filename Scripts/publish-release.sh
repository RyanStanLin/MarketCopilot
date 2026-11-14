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
release_payload="$(mktemp "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/MarketCopilot-release.XXXXXX")"
trap 'rm -f -- "$release_payload"' EXIT

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

# The tag endpoint only serves published releases. List drafts for resuming a run.
release_id="$(gh api "repos/${GITHUB_REPOSITORY}/releases?per_page=100" --paginate \
    --jq ".[] | select(.tag_name == \"${release_tag}\") | .id")"
if [[ -n "$release_id" ]]; then
    is_draft="$(gh api "repos/${GITHUB_REPOSITORY}/releases/${release_id}" --jq '.draft')"
    if [[ "$is_draft" == false ]]; then
        # A successful rerun keeps published assets intact, including immutable releases.
        gh release view "$release_tag" --repo "$GITHUB_REPOSITORY" --json url --jq '.url'
        exit 0
    fi
else
    python3 - <<'PY' > "$release_payload"
import json
import os
body = "\n".join([
    "macOS 27+ · Apple Silicon (arm64)\n",
    "Download the DMG and drag MarketCopilot to Applications.",
    "下载 DMG，将 MarketCopilot 拖入 Applications 即可安装。\n",
    "Built with local ad-hoc signing; Developer ID signing and notarization are not configured.\n",
    f"Source commit: `{os.environ['GITHUB_SHA']}`",
    f"Build: {os.environ['GITHUB_RUN_NUMBER']}",
])
version = os.environ["MARKETCOPILOT_VERSION"]
json.dump({
    "tag_name": f"v{version}", "target_commitish": os.environ["GITHUB_SHA"],
    "name": f"MarketCopilot {version}", "body": body, "draft": True,
    "generate_release_notes": True,
}, fp=__import__("sys").stdout)
PY
    release_id="$(gh api --method POST "repos/${GITHUB_REPOSITORY}/releases" \
        --input "$release_payload" --jq '.id')"
fi

gh release upload "$release_tag" "${release_assets[@]}" --repo "$GITHUB_REPOSITORY" --clobber
# GitHub chooses Latest by date / semantic version even if builds finish out of order.
release_url="$(gh api --method PATCH "repos/${GITHUB_REPOSITORY}/releases/${release_id}" \
    -F draft=false -f make_latest=legacy --jq '.html_url')"
printf '%s\n' "$release_url"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '[Download MarketCopilot %s](%s)\n' "$MARKETCOPILOT_VERSION" "$release_url" >> "$GITHUB_STEP_SUMMARY"
fi
