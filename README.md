# MarketCopilot

Native macOS 27 menu bar portfolio viewer for Polymarket Predictions and Perps.

Built with SwiftUI, AppKit and SwiftData, using official Polymarket APIs. Account credentials stay in the macOS Keychain; wallet private keys are never required.

## Build

Requires Xcode 27 (Swift 6.4). Open `MarketCopilot.xcodeproj`, or run `zsh Scripts/build.sh`.
The local ad-hoc signed app is written to `build/Build/Products/Debug/MarketCopilot.app`.

## Design reference

- [Menu states](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=2-4070)
- [Head icons](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=1-3545)

Implementation proceeds in small, buildable Git commits.
