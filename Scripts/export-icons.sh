#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

icon_tool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
if [[ ! -x "$icon_tool" ]]; then
    print -u2 'Select Xcode 27 or newer to export the native Icon Composer artwork.'
    exit 1
fi

mkdir -p Docs/Assets
for icon_rendition in Default Dark; do
    icon_appearance=light
    if [[ "$icon_rendition" == Dark ]]; then icon_appearance=dark; fi
    "$icon_tool" App/Resources/AppIcon.icon --export-image \
        --output-file "Docs/Assets/AppIcon-${icon_appearance}.png" \
        --platform macOS --rendition "$icon_rendition" \
        --width 256 --height 256 --scale 2 --design-generation 27
done
