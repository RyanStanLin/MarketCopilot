#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
xcodebuild -project MarketCopilot.xcodeproj -scheme MarketCopilot -configuration Debug -derivedDataPath build CODE_SIGN_IDENTITY=- build
print "App: ${PWD}/build/Build/Products/Debug/MarketCopilot.app"
