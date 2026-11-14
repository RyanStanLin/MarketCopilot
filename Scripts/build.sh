#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
build_configuration="${1:-Debug}"
typeset -a version_arguments=()
if [[ -n "${MARKETCOPILOT_VERSION:-}" ]]; then
    if [[ "$MARKETCOPILOT_VERSION" != <->.<->.<-> ]]; then
        print -u2 'MARKETCOPILOT_VERSION must contain three numeric components.'
        exit 1
    fi
    version_arguments+=("MARKETING_VERSION=${MARKETCOPILOT_VERSION}")
fi
if [[ -n "${MARKETCOPILOT_BUILD_NUMBER:-}" ]]; then
    if [[ "$MARKETCOPILOT_BUILD_NUMBER" != <-> ]]; then
        print -u2 'MARKETCOPILOT_BUILD_NUMBER must be a positive integer.'
        exit 1
    fi
    version_arguments+=("CURRENT_PROJECT_VERSION=${MARKETCOPILOT_BUILD_NUMBER}")
fi
if ! xcrun metal --version >/dev/null 2>&1; then
    xcodebuild -downloadComponent MetalToolchain
fi
xcodebuild -project MarketCopilot.xcodeproj -scheme MarketCopilot -configuration "$build_configuration" -destination 'platform=macOS' -derivedDataPath build CODE_SIGN_IDENTITY=- ONLY_ACTIVE_ARCH=YES "${version_arguments[@]}" build
print "App: ${PWD}/build/Build/Products/${build_configuration}/MarketCopilot.app"
