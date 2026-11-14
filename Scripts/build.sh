#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
build_configuration="${1:-Debug}"
if ! xcrun metal --version >/dev/null 2>&1; then
    xcodebuild -downloadComponent MetalToolchain
fi
xcodebuild -project MarketCopilot.xcodeproj -scheme MarketCopilot -configuration "$build_configuration" -destination 'platform=macOS' -derivedDataPath build CODE_SIGN_IDENTITY=- ONLY_ACTIVE_ARCH=YES build
print "App: ${PWD}/build/Build/Products/${build_configuration}/MarketCopilot.app"
