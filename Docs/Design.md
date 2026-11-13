# Figma implementation contract

Source nodes: menu `2:4070`; head icons `1:3545`.

- Menu: 308 pt wide, 16 pt radius, 14 pt horizontal insets.
- Collapsed: 327 pt. Expanded with two positions: 662 pt.
- Position: 141 pt; metric groups indented 40 pt; row spacing 10 pt; metric spacing 12 pt.
- Drawer: full-width top and bottom borders, semantic translucent fill; replaces the collapsed inset separator.
- Drawer motion: one spring progress controls the clipped drawer height, inset separator and Cash position. Contents remain fully laid out below the 159 pt parent section. The AppKit window follows the rendered height without its own animation and keeps its top-left anchor fixed, including when an animation is reversed.
- Every menu option has the updated Figma hover background. The Perps disclosure rotates right/down, and its icon is accent blue only while expanded.
- SF Pro 13 pt bold headings, SF Pro Rounded 15 pt amounts, SF Pro 12 pt captions.
- Status: 13/10 pt two-line columns, 8 pt horizontal gap, -3 pt vertical gap; scale the complete 26 pt design uniformly on shorter menu bars.

The three `Figma*` image assets are the exact supplied visual fixtures. They are used only by explicit design previews. Live account avatars and instrument logos come from official profile/instrument APIs, including light/dark logo variants. No temporary Figma URL is used at runtime.

Apple library Code Connect entries describe macOS menu separators and menu actions. These are implemented with native AppKit/SwiftUI behavior, within the custom menu surface needed for the supplied drawer layout. There was no existing application component library to reuse.

Dark appearance uses native label/material colors and appearance variants for the Figma fill tokens. Financial signs and text remain in the source design's colors; no unsolicited red/green styling is added.
The application follows system appearance changes in real time; no runtime light/dark override is applied.
