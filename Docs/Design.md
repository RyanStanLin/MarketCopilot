# Figma implementation contract

Source nodes: updated Perps menu `2:4069`, Prediction menu `10:138`; head icons `1:3545`.

- Menu: 308 pt wide, 16 pt radius, 14 pt horizontal insets.
- Collapsed: 404 pt, including health rows and Quit. Perps with more than two rows: 843 pt at its full 450 pt drawer height. Two full Prediction rows: 862 pt as in the supplied frame, subject to the screen's available height.
- Perps position: 147 pt; Prediction: 191 pt; metric groups indented 40 pt; row spacing 10 pt on each side of an 11 pt separator; metric spacing 12 pt.
- Perps header: 41 pt, icon 32 pt plus 2 pt vertical padding, title/token gap 2 pt. Prediction title area: 60 pt, token/share gap 6 pt. Token: 19 pt high, 6 pt corner radius, leading pill insets 6/4/2, trailing pill 4/4/2. Labels use condensed 12 pt; trailing values use rounded 12 pt.
- Drawer: full-width top and bottom borders, system `.fill.quaternary` background; replaces the collapsed inset separator.
- Drawer motion: one spring progress controls the clipped drawer height, inset separator and Cash position. Contents remain fully laid out below the 159 pt parent section. The AppKit window follows the rendered height without its own animation and keeps its top-left anchor fixed, including when an animation is reversed.
- Every menu option has the updated Figma hover background. The Perps disclosure rotates right/down, and its icon is accent blue only while expanded.
- SF Pro 13 pt bold headings, SF Pro Rounded 15 pt amounts, SF Pro 12 pt captions.
- Status: 13/10 pt two-line columns, 8 pt horizontal gap, -3 pt vertical gap; scale the complete 26 pt design uniformly on shorter menu bars.

The four `Figma*` image assets are the exact supplied visual fixtures, including the supplied Prediction market image. They are used only by explicit design previews. Live account avatars, market images and instrument logos come from official APIs, including light/dark instrument logo variants. No temporary Figma URL is used at runtime.

Apple library Code Connect entries describe macOS menu separators and menu actions. These are implemented with native AppKit/SwiftUI behavior, within the custom menu surface needed for the supplied drawer layout. There was no existing application component library to reuse.

Dark appearance uses native label/material colors and appearance variants for the Figma fill tokens. Financial signs and text remain in the source design's colors; no unsolicited red/green styling is added.
The application follows system appearance changes in real time; no runtime light/dark override is applied.

The title arrow represents the sign of the official position's unrealized PnL. It updates with the account stream and switches between `arrow.up.right.circle.fill` and `arrow.down.right.circle.fill`; it does not compare prices. English, Simplified Chinese and Traditional Chinese use localized string resources while retaining the same menu geometry.

The Perps and Prediction drawers share one clipped, top-anchored layout. Above two positions their maximum height is 450 pt; smaller lists use their natural Figma height, including the 467 pt two-market Prediction example. Per the subsequent design correction, gray edge shadows are replaced by transparent progressive blur across a 65 pt band. The public SwiftUI `layerEffect` shader samples a variable-radius Gaussian approximation and fades premultiplied alpha into the native quaternary surface; no tinted overlay or private blur API is used.

The Metal shader varies scale per scanline from 1 to 0.95, using the lower anchor above the viewport and the upper anchor below it. It does not apply one uniform scale to a whole row. Spatial and scroll-distance ramps use quintic smootherstep, with zero slope and curvature at each endpoint. Edge strength eases in across the first 24 pt of scrolling and is independently interpolated over 0.16 seconds, avoiding a Boolean switch when leaving or reaching either end. Reduce Motion disables perspective while retaining blur.

The scroll viewport spans the full 308 pt drawer. Content retains its 14 pt alignment inset, with an additional 6 pt raster gutter on either side of each card for the hover background. Native horizontal elasticity is disabled and the document width is fixed, preventing sideways trackpad wobble without exposing drawer contents outside the vertical clip.

The 234 pt footer has Cash, its two summaries, an inset separator, two 22 pt health rows, another inset separator, Settings and Quit, plus 8 pt bottom padding. Health labels are 11 pt medium and values 11 pt light. Live metric color is generated from native green/red composited with Secondary Label and fades to each metric's original label style; per-metric controls and duration are persisted.
