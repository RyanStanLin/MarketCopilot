# Validation

## Reproducible checks

- `swift test`: Swift Testing suites with injected HTTP and socket transports. No live credentials, database files or external services in unit tests.
- `swift run market-probe`: real CLOB server time, Prediction v2 public decoding, Perps instrument/mark/bid/ask reads and public WebSocket ticker.
- `zsh Scripts/validate.sh`: Debug app build, isolated Keychain service, in-memory SwiftData, exact design geometry and light/dark component renders.
- `zsh Scripts/build.sh Release`: locally signed production app, with sample data mode disabled.

## Requirement evidence

| Requirement | Evidence |
|---|---|
| Totals include cash once and sum available products | `totalsIncludePredictionCashWithoutDoubleCountingPerpsCash`, `totalsUseAvailableProductsAndKeepEntirelyMissingBalancesUnavailable`, `confirmedEmptyAccountsAreValidZeroBalances` (assertions updated; not rerun after the user's request to skip checks) |
| Exact money, percentage and Funding representation | `exactStringAndNumberAmountsNeverPassThroughDouble`, `malformedAndUnavailableAmountsAreRejected`, `formattingPreservesSignedMoneyAndFundingPrecision` |
| Official CLOB signing and cash units | `signsCanonicalPathWithUrlSafeHmacAndPreservesPadding`, `cashUsesSignerHeadersWalletTypeAndSixDecimalUnits` |
| Complete Prediction positions and v2 envelope | `walksAllPositionCursorsKeepingWalletAnchorAndDeduplicatingTokens`, `rejectsRepeatingCursorsInsteadOfReturningPartialHoldings`, `decodesPortfolioNumbersAsDecimalAndMissingCashStaysUnavailable` |
| Full Perps position mapping, both directions, empty holdings | `decodesShortPositionsAndAuthoritativeEquityWithoutAddingNotional`, `zeroSizeIsRemovedAndUnliquidatableLongHasNoInventedPrice`, `missingPrivateFieldsAreErrorsInsteadOfInventedZeroes` |
| Perps credential acceptance, owner mismatch and expiry | `acceptsMatchingOwnerAndUnexpiredProxy`, `validatesOwnerAndRejectsExpiredProxies` |
| Dynamic display labels, precision, light/dark logos, bid/ask | `metadataUsesDisplaySymbolPrecisionAndLightDarkLogos`, `quoteReadsSeparateMarkFromBidAndAsk` |
| WebSocket wire formats, ordered authentication and heartbeat | `tickerAndBookFramesPreserveDistinctPricesAndRejectOldSequences`, `portfolioPushUsesTheSameAuthoritativeFieldsAsRest`, `subscriptionsAuthenticateBeforeSubscribingAndUseOfficialHeartbeat`, `rejectedAuthenticationNeverSendsPrivateSubscriptions` |
| No stale account responses or duplicated requests | `accountSwitchDiscardsOldInFlightResponses`, `simultaneousRefreshRequestsShareOneInFlightRead` |
| Cache preservation, rate limits, reconnect bounds | `authFailureRetainsCacheAndStopsAutomaticRetries`, `retryAfterBlocksEvenForcedRefreshUntilItsBoundary`, `rateLimitPreservesRetryAfterWithoutExposingResponseSecrets`, `retryBackoffIsBoundedAndHonorsServerDelay` |
| Polling choice and silent-stream fallback | `pollingModeCreatesNoWebSocketSubscriptions`, `quietPortfolioStreamFallsBackToPollingAfterFifteenSeconds` |
| Quote merge and stale update protection | `olderRestSnapshotsCannotReplaceNewerPushAndQuoteUpdatesMerge`, `emptyOrderBookClearsOldBidAskWithoutDiscardingMark` |
| Account and interval validation | `validatesAddressesWithoutConfusingSignerAndAccount`, `rejectsPartialCredentialSetsButAllowsPublicAddressSetup`, `refreshIntervalsEnforceFiniteBoundaries` |
| Status click toggles without an outside-dismiss race | `statusItemClickIsNotAnOutsideDismissBeforeItsToggleAction` |
| Drawer animation shares one layout progress and preserves the window anchor | `drawerResizeKeepsTopAndLeftEdgesFixedThroughoutTheAnimation`, `drawerAndSeparatorShareOneProgressWithoutChangingTheirCombinedLayout`, `springOvershootCannotRevealDrawerPastItsViewportOrMoveCollapsedContent` |
| Figma geometry, assets, real native storage | Native checks `collapsedGeometry`, `expandedGeometry`, `drawerClampsToScreen`, `staticAssetsPresent`, `swiftDataAccount`, `swiftDataSettings`, `swiftDataExactDecimalCache`, `swiftDataAccountIsolation`, `keychainRoundTrip`, `keychainIdentityIsolation`, `keychainDelete` |
| Automatic native light/dark colors | Native checks `followsSystemAppearance`, `fillColorsAdaptToAppearance` |

The drawer revision passed the four focused `MenuInteractionTests` and a Debug build. `--design-preview --validate-motion` sampled 171 native frames across opening, closing and an interrupted reversal. All six checks passed: `sampledIntermediateFrames`, `windowTopAndLeftStayFixed`, `headerStaysAtTop`, `drawerContentStaysBelowParent`, `cashFollowsClippedViewport`, `reversedAnimationReturnsToCollapsedHeight`. The complete two-position fixture is used independently of the status bar's initial screen-height constraint. Geometry sampling verifies positions, not composited pixels.

The user requested skipping further checks. The subsequent Google-account simplification, stable position order, square icons, price-direction arrows, full-row links and partial totals were implemented with tests and UI checks skipped as requested. Existing total assertions were adjusted to the new behavior but not run. The Release build succeeded to produce the installed application. The on-chain cash path and profile resolver have not been exercised with a live account in this revision.

The later arrow correction uses the sign of official `unrealized_pnl`, as clarified by the user, rather than price direction. English / Simplified Chinese / Traditional Chinese resources, persisted language and Cash offset, `.fill.quaternary` and bitmap-normalized logo loading were added. The official DOGE SVG was inspected: one 2000×2000 PNG is referenced through an object-bounding-box pattern inside a 1220×1220 SVG. That simple wrapper is extracted before bitmap normalization. The latest Release builds succeeded; behavioral tests and visual checks remain skipped at the user's request. The DMG workflow is prepared locally; repository creation, push and remote execution are deferred by the user.

Cash offsets were subsequently split into Predictions and Perps values. `BalancePresentation` applies each once to that product's Cash and Portfolio, and both menu sections and status-bar totals consume the same presentation. Raw API snapshots and persisted caches remain unchanged. Legacy combined offset data migrates to Perps; subsequent saves write only the two explicit offsets.

## Updated Figma drawers

The new implementation uses high-fidelity contexts and screenshots for nodes `2:4069` and `10:138`, including the Prediction row, token and shadow child nodes. Full Prediction details were mapped against the official Data API v2 OpenAPI `Position` schema: `current_size`, `avg_price`, `current_price`, `current_value`, `unrealized_pnl`, and `percent_pnl` (a percentage, divided by 100 for the existing ratio formatter). Both products preserve existing position ordering.

The Release build includes the Apple Metal Toolchain and compiles the scanline-dependent drawer shader. New source covers mutually exclusive drawers, keyboard scrolling, conditional edge shadows, health timestamps/channels, tokens, Quit, localized labels and per-metric live color preferences. Updated debug rendering supports both drawer designs and both appearances. At the user's request, no new test execution, native motion sampling, screenshot comparison or live-account acceptance was performed for this redesign; source-derived geometry is not represented as pixel-overlay verification. GitHub creation/push remains deferred.

## Visual verification limits

The component render uses the exact local Figma avatar/US100/NVDA assets, typography and spacing. Native material is deliberately replaced by a neutral static surface for ImageRenderer, since ImageRenderer cannot composite an AppKit glass view or capture the desktop backdrop. These images verify component layout and assets; they are not represented as live screenshots or proof of final material pixels.

Settings screenshots and native menu expansion through accessibility were obtained earlier. Capturing the floating menu remained unreliable (ScreenCaptureKit `-3811`); the latest app connection attempts timed out (`-10005`). A visible-desktop pixel overlay of the revised animation, multi-monitor behavior and physical sleep/wake remain unverified. Private authenticated account validation remains pending until the user enters their own credentials in the app.
