#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

release_app="${PWD}/build/Build/Products/Release/MarketCopilot.app"
output_directory="${PWD}/dist"
if [[ ! -x "${release_app}/Contents/MacOS/MarketCopilot" ]]; then
    print -u2 'Build the Release app first: zsh Scripts/build.sh Release'
    exit 1
fi
mkdir -p "$output_directory"
app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${release_app}/Contents/Info.plist")"
commit_short="$(git rev-parse --short HEAD)"
build_architecture="$(uname -m)"
dmg_path="${output_directory}/MarketCopilot-${app_version}-macOS-${build_architecture}-${commit_short}.dmg"
staging_directory="$(mktemp -d "${TMPDIR:-/tmp}/MarketCopilot-dmg.XXXXXX")"
trap 'rm -rf -- "$staging_directory"' EXIT

ditto "$release_app" "${staging_directory}/MarketCopilot.app"
ln -s /Applications "${staging_directory}/Applications"
cat > "${staging_directory}/Read Me.txt" <<'TEXT'
MarketCopilot — macOS 27+

Drag MarketCopilot to Applications, then open it from Applications.
Click Portfolio / Cash in the menu bar to open the menu, then Settings.
Predictions: enter your wallet address, @username or Polymarket profile URL.
Perps: enter an official delegated session proxy address and secret.
General: choose English / 简体中文 / 繁體中文 and set separate Predictions / Perps Cash offsets.
Each offset is included once in that account's Cash and Portfolio, including menu-bar totals.
Indicators: enable Live color indicator, choose individual metrics and set the fade duration.
Use the up/down arrow keys or a trackpad to scroll the expanded drawer.

将 MarketCopilot 拖入 Applications，再从“应用程序”启动。
点击菜单栏的总资产 / 现金打开菜单，在设置中连接账户。
Google / 邮箱的预测市场账户仅需钱包、@用户名或个人主页链接。
永续合约需要官方委托会话的代理地址与 Secret。
“通用”中可切换语言，并分别设置预测市场 / 永续合约的正负现金偏移。
每项偏移同时影响对应账户的现金、总资产，以及菜单栏合计。
“指标”中可单独设置各项数值的实时变色提示与渐变时长。
展开抽屉后可使用上下方向键、滚轮或触控板逐项滚动。
TEXT
hdiutil create -volname MarketCopilot -srcfolder "$staging_directory" -format UDZO -ov "$dmg_path"
(cd "$output_directory" && shasum -a 256 "${dmg_path:t}" > "${dmg_path:t}.sha256")
print "DMG: ${dmg_path}"
