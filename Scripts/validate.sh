#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift test
zsh Scripts/build.sh Debug
app_executable="${PWD}/build/Build/Products/Debug/MarketCopilot.app/Contents/MacOS/MarketCopilot"
"$app_executable" --design-preview --validate-native
"$app_executable" --design-preview --render-design
validation_source="$HOME/Library/Containers/in.ryanl.MarketCopilot/Data/Library/Caches/DesignValidation"
mkdir -p build/Validation
cp "$validation_source"/*.png "$validation_source"/*.json "$validation_source"/geometry.txt build/Validation/
python3 - <<'PY'
import json
from pathlib import Path
report = json.loads(Path('build/Validation/native-validation.json').read_text())
assert report['passed'] and all(report['checks'].values()) and not report['errors'], report
print(f"Native validation: {len(report['checks'])} checks passed")
PY
print 'Component renders and native validation: build/Validation/'
