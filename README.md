<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Docs/Assets/AppIcon-dark.png">
  <img src="Docs/Assets/AppIcon-light.png" width="128" height="128" alt="MarketCopilot app icon">
</picture>

# MarketCopilot

原生 macOS 27 菜单栏应用，分别查看 Polymarket Predictions 与 Perps 的资产、现金和永续持仓。

采用 SwiftUI、AppKit、SwiftData 和官方 Polymarket REST / WebSocket，无第三方依赖。API 凭证仅保存到 macOS Keychain，不需要钱包私钥。

应用图标保留原生 Icon Composer 的分层、材质及深浅外观，源码位于 [`AppIcon.icon`](App/Resources/AppIcon.icon)。README 使用同一图标的系统渲染，随 GitHub 深浅主题切换；修改图标后运行 `zsh Scripts/export-icons.sh` 同步两份预览。

## Build

需要运行 macOS 27 或更高版本的 Mac，以及 Xcode 27 / Swift 6.4 或更新版本。本机脚本构建当前 Mac 的架构，GitHub Actions 生成 Apple Silicon 安装包。项目不依赖 Homebrew、CocoaPods 或其他第三方 Swift 包。

抽屉的逐像素透视与透明渐进模糊使用系统公开的 SwiftUI `layerEffect` 和 Metal，无第三方模糊库或私有 API。构建脚本会在缺少 Metal Toolchain 时自动下载 Apple 官方组件；也可预先运行 `xcodebuild -downloadComponent MetalToolchain`。GitHub Actions 使用同一构建脚本。

从 [GitHub 仓库](https://github.com/RyanStanLin/MarketCopilot) 下载源码，或克隆默认 `main` 分支：

```sh
git clone https://github.com/RyanStanLin/MarketCopilot.git
cd MarketCopilot
```

打开 `MarketCopilot.xcodeproj`，选择 MarketCopilot scheme 和 My Mac 后运行；也可以在源码目录运行：

```sh
zsh Scripts/build.sh Debug
zsh Scripts/build.sh Release
zsh Scripts/install.sh
```

应用位于 `build/Build/Products/Debug/MarketCopilot.app` 或 `build/Build/Products/Release/MarketCopilot.app`。脚本为本机架构构建并本地签名；可直接运行。分发给其他 Mac 的 Developer ID 签名和公证需要另行配置证书。

安装本机发行版：`zsh Scripts/install.sh`。默认安装到 `/Applications/MarketCopilot.app` 并打开设置；已有版本先备份到 `~/Library/Application Support/MarketCopilot/Previous Versions/`，账户数据和 Keychain 不会被删除。

构建 DMG：

```sh
zsh Scripts/build.sh Release
zsh Scripts/package-dmg.sh
```

生成文件位于 `dist/MarketCopilot-<版本>-macOS-<架构>-<commit>.dmg`，同时提供 SHA-256 文件。打开 DMG，将应用拖到 Applications 即可。默认是本地临时签名，不包含 Developer ID 签名或 Apple 公证；正式对外分发时需要自己的开发者证书。

## CI/CD：自动版本与 DMG Release

[`.github/workflows/build-dmg.yml`](.github/workflows/build-dmg.yml) 监听所有分支和 tag 的每次 push，也支持 Actions 页手动运行。流程在 GitHub 的 `xcode-27` runner 上选择 Xcode 27 或更新版本，编译 Release、创建 DMG，并上传 DMG 与 SHA-256。每次运行独立保留产物，不会因为后续 push 而取消前一次构建。项目默认分支为 `main`。

`main` 构建成功后会自动创建版本标签和 [GitHub Release](https://github.com/RyanStanLin/MarketCopilot/releases)，附 DMG、SHA-256 和自动生成的变更说明；两份附件上传完成后才公开发布。其他分支和 tag 仅保留 Actions 产物，不发布正式 Release。所有构建都从触发该次运行的确切 commit 生成，标签指向同一个 commit。

- 自动版本读取 Xcode 项目的 Release `MARKETING_VERSION`，补丁号加上 `GITHUB_RUN_NUMBER`。当前基准 `1.0.0` 首次生成 `1.0.1`，随后递增；应用内版本、DMG 文件名和 `v1.0.1` 标签一致，`CFBundleVersion` 使用运行序号。
- 每次新运行分配唯一版本；失败构建或其他分支构建可能留下版本空号。重跑同一次运行保持原版本，已经公开的 Release 附件保持原样，未完成的草稿可继续上传并发布。无需回写版本提交，也不会形成 CI 循环。调整大/小版本时，在 Xcode 的 Release 版本中修改基准值。
- 正式安装包下载：[Releases / Latest](https://github.com/RyanStanLin/MarketCopilot/releases/latest)。每次构建的临时产物下载：**Actions → Build DMG → 对应运行 → Artifacts**，保留 30 天。
- 构建任务只有源码读取权限，独立发布任务使用 GitHub 自动提供的短期 `GITHUB_TOKEN` 写入 Release；无需 PAT、Polymarket 账户密钥或额外仓库 Secret。GitHub runner、版本序号和发布行为依据[官方 runner 列表](https://github.com/actions/runner-images)、[Actions 变量](https://docs.github.com/en/actions/reference/workflows-and-actions/variables)和 [Release API](https://docs.github.com/en/rest/releases/releases)配置。

本地构建默认沿用 Xcode 项目中的版本。需要手动指定发行版版本时：

```sh
MARKETCOPILOT_VERSION=1.2.3 MARKETCOPILOT_BUILD_NUMBER=123 zsh Scripts/build.sh Release
zsh Scripts/package-dmg.sh
```

## 连接账户

点击菜单栏的 Portfolio / Cash → Settings → Account：

1. **Predictions → Wallet or profile**：粘贴账户钱包地址、`@用户名` 或 Polymarket 个人主页链接。Google / 邮箱登录账户同样适用，不需要 CLOB key 或钱包签名。用户名通过官方 Gamma API 精确匹配；无法唯一匹配时使用个人菜单中的账户钱包地址。
2. **Perps**：填写官方 Perps delegated session 的 proxy address 和 secret；可额外填写预期账户 owner。只连接 Perps 时可留空 Predictions；应用会从官方凭证接口确认 owner。
3. 点击 **Save & Connect**；Updates 页显示各数据源的连接状态。

Predictions 使用官方公开 Data / Gamma API，并通过 Polygon 官方文档列出的公共 RPC，读取 Polymarket 官方 pUSD 合约的 `balanceOf`；请求只包含 `eth_chainId` / `eth_call`，不创建授权、不提交交易。合约与网络配置在 `Sources/MarketCore/Resources/Endpoints.json`。见 [官方钱包说明](https://docs.polymarket.com/trading/wallets-auth)、[pUSD 合约](https://docs.polymarket.com/resources/contracts) 和 [Polygon RPC](https://docs.polygon.technology/pos/reference/rpc-endpoints)。

已有 CLOB L2 凭证可在折叠的 **Advanced Predictions access** 中选填，用于私有订单/成交通知；正常读取资产和现金不依赖这些凭证。Perps 明细仍需要 [官方 session 凭证](https://docs.polymarket.com/perps/authenticated-sessions)。单个来源尚未配置或不可用时，菜单栏汇总已有来源；只有完全没有可用数据时才显示 `—`。悬停说明会标明汇总包含的可用部分。

### 各项 Key 应该填什么

| 用途 | 设置字段 | 获取与要求 |
|---|---|---|
| Predictions 默认只读 | Wallet or profile | 从 Polymarket 个人菜单复制账户钱包，或使用个人主页 / @用户名。Google、邮箱、外部钱包账户均可，不需要 API key。 |
| Predictions 高级通知（可选） | Signer address、Wallet type、API key、API secret、Passphrase | 使用官方 CLOB L2 认证流程创建或派生的三项凭证及对应签名者地址。见 [CLOB 认证](https://docs.polymarket.com/getting-started/api#authentication)。Builder / Relayer Key 不能代替 CLOB L2 Key。 |
| Perps | Proxy address、Proxy secret | 使用已授权的官方 Perps delegated session。见 [官方会话建立与授权步骤](https://docs.polymarket.com/perps/authenticated-sessions)。填该会话的 proxy 地址和 secret，不是 Predictions CLOB Key，也不是钱包私钥。 |
| Perps 身份核对（可选） | Account owner | 填预期的账户 owner 地址。应用会用官方凭证接口验证会话归属与有效期。 |

Google / 邮箱登录方式本身不决定高级配置的 Wallet type：2026 年 5 月 4 日起新部署账户使用 Deposit Wallet，更早的 Google / Magic 账户可能使用 Legacy Proxy。请按[官方钱包类型说明](https://docs.polymarket.com/trading/wallets-auth)选择；默认只读方式无需选择这些类型。

创建 Perps 会话涉及官方钱包授权与签名，请按官方流程在钱包或 SDK 中完成，再把生成的会话凭证填入应用。MarketCopilot 负责导入和验证现有会话，不要求你把钱包私钥交给应用，也不会自行创建交易授权。所有真实 Key 只填在本机设置中，不放进源码、README、GitHub Actions 或仓库 Secret。

## 使用与更新

- 菜单栏持续显示两类资产的合计 Portfolio 与合计 Cash。
- 打开菜单或展开任一抽屉会立即请求最新数据。Predictions 的 Markets 只展示当前仍有份额的活跃持仓，排除已退出、已结算待赎回和归档市场；展示市场问题、Yes / No 和平均单价 token、当前份数、价值、收益与百分比、平均价及当前价。Perps 展示 Long / Short 与杠杆 token、收益及六项明细。官方组合估值仍独立读取，不因抽屉筛选而被重算。
- 两种抽屉按手风琴方式切换，打开 Predictions 会把 Perps 汇总行向下推，菜单顶边保持固定。超过两类持仓时，抽屉最多 450 pt，可使用滚轮、触控板或上下方向键逐项滚动。屏幕空间不足时也会缩小视口并允许滚动。
- 卡片之间保留设计中的分隔线。滚动到顶部仅保留下方 65 pt 透明渐进模糊，到底部仅保留上方，中间两侧都有；没有灰色阴影遮罩。模糊半径和透明度逐像素变化，逐渐露出原生 quaternary 背景。视口边缘使用每条扫描线不同的 Metal 变换，从 1× 平滑过渡到 0.95×；下方内容锚定顶部、上方内容锚定底部，不对整张卡片统一缩放。边缘效果同时随离开端点的滚动距离连续增强，24 pt 内缓入，并以 0.16 秒动画平滑衔接，到达端点时缓出。减少动态效果开启时取消透视，保留模糊。
- 抽屉固定文档宽度并通过公开 AppKit API 关闭横向弹性，触控板横扫不会让内容左右回弹。滚动视口延伸至抽屉全宽，卡片两侧保留 hover 所需空间；圆角背景完整呈现，垂直裁剪仍限制在抽屉内部。
- 两种抽屉始终启用纵向滚动与弹性，即使只有一两条持仓且内容完全放得下，触控板快速上下滑动仍交给原生 `NSScrollView` 处理惯性减速与越界回弹（overshoot）。透明渐进模糊与 0.95× 透视连续跟随真实滚动位移，在惯性、越界和回弹期间同样生效；短列表回到静止位置时自然消退。卡片间距与抽屉高度保持不变。
- 持仓更新保留已有显示顺序，新持仓追加到底部；关闭后移除。图标固定为 32×32。标题箭头使用官方未实现收益 `unrealized_pnl` 的正负：非负向上、负数向下，随持仓更新切换；点击整张持仓打开 Polymarket Perps。
- 抽屉使用系统 `.fill.quaternary` 背景，实时适应深浅外观。远程图标先生成完整的固定方形位图；DOGE 这类内嵌 PNG 的简单 SVG 包装会先解包，避免只显示局部图案。
- General / 通用 → Language / 语言：支持跟随系统、English、简体中文与繁體中文，选择后立即生效并保存。
- General / 通用 → Cash offsets / 现金偏移：分别填写 Predictions 和 Perps 的 `-500`、`+10` 或普通小数，点击应用或按回车。每项 offset 同时影响该产品在菜单中的 Cash 和 Portfolio，菜单栏合计再把两类调整后的金额相加。设置会自动保存，无需重新连接账户。
- offset 只作用于显示层，官方原始数据与缓存保持原值；不会在每次刷新后重复叠加，也不改变持仓头寸、保证金、Funding 或盈亏。缺少来源且未设置偏移时显示 `—`；显式设置非零偏移时可显示该手动金额，悬停仍会说明数据源不可用。旧版的单一合计 offset 会一次性迁移到 Perps offset，可在设置中重新分配。
- 点击行情数值可通过悬停说明查看 mark / bid / ask。原稿 `Liq. price` 表示清算价。
- Updates 可分别选择 WebSocket 优先或仅轮询，设置 1–300 秒轮询间隔和 10–600 秒校准间隔。
- 官方 Perps 账户推送约每 5 秒一次；行情推送可以更快，画面合并到最多每秒 4 次，避免数字动画反复打断。
- 关闭菜单后继续更新；休眠暂停，唤醒和网络恢复后重新同步。断线、限流及凭证过期会在悬停说明和设置中显示，保留最后有效值及时间。
- General 可设置开机启动、断开账户或退出。断开账户删除本机凭证与对应资产缓存，不影响 Polymarket 账户。
- 菜单底部 Settings 上方显示两类账户的最近成功更新时间及刷新渠道（WebSocket、Polling、Cache），并标识过期或不可用；悬停可查看完整连接状态。时间依据成功账户快照，连接成功或心跳不会冒充数据更新。菜单底部提供 **Quit MarketCopilot / 退出 MarketCopilot**。
- **Indicators / 指标 → Live color indicator / 实时变色指示**：总开关与每项独立开关覆盖投资组合、现金、Now、Entry、清算价、头寸、保证金、Funding、收益、收益百分比，以及预测价值、平均价、当前价、份数、杠杆和 token 单价。数值较上次增加时立即闪绿，减少时闪红，数字和相应 caption 一起在设置的 0.1–10 秒内渐变回原色。提示色叠加系统 Secondary Label 色，自动适应深浅模式。首次载入或数值未变时不闪色。

## 持仓通知

右键点击任一 Prediction 市场或 Perps 合约，菜单中只有 **Set notifications… / 设置通知…**，打开独立的通知配置窗口。每个持仓支持多条规则，可编辑、暂停、重新启用或删除；**Settings → Notifications / 设置 → 通知** 汇总所有已保存规则，也能管理已经不在抽屉中的市场。通知使用 macOS 原生通知中心，不需要新增 API Key 或第三方服务。

| 触发器 | 口径 |
|---|---|
| 价格上穿 / 下穿 | 上一次在阈值外、这一次达到或越过阈值时触发。Perps 使用 mark；Prediction 对应所持 Yes / No token 的当前价格，输入单位为美分（0–100¢）。 |
| 短时急涨 / 急跌 | 最新价格相对一个完整时间窗口前的价格变动。默认 Perps 为 **5 分钟 ±3%**；Prediction 为 **5 分钟 ±5¢（5 个百分点）**，也能切换相对百分比。时间窗可选 1、5、15、30、60 分钟，阈值可编辑。 |
| 未实现盈亏上穿 / 下穿 | 官方未实现盈亏的 USD 金额；可输入负数作为亏损阈值，例如 `-50`。Cash offset 不参与计算。 |
| 收益率上穿 / 下穿 | 官方回报率百分比，Perps 使用 ROE，Prediction 使用官方 `percent_pnl`；可设正值、零或负值。 |
| 接近清算价（Perps） | 多仓 `(mark − liq) / mark × 100%`，空仓 `(liq − mark) / mark × 100%`；默认距离阈值 5%，可修改。没有官方清算价时不评估。当前新数据已经处于阈值内时，可以立即提醒。 |
| 累计 Funding 上穿 / 下穿（Perps） | 与抽屉相同的官方累计 Funding，使用其原始带符号 USD 值，不自行猜测支付/收取方向。 |
| 持仓退出活跃列表 | 先观测到活跃持仓，再收到已不在列表中的最新完整账户快照时触发；可能是卖出、平仓或市场结束，不推断具体成交原因。 |

上穿 / 下穿及时间窗口涨跌属于常见的提醒条件，参考 [TradingView 官方说明](https://www.tradingview.com/support/solutions/43000763312-learn-how-to-configure-alerts/)。`3% / 5¢ / 5 分钟` 是本应用的可调整默认值，不是所有市场统一规定的阈值。相对涨跌公式为 `(现价 − 窗口前价格) / 窗口前价格 × 100%`；Prediction 美分变动为两次原始价格之差乘 100。新建、编辑、重新连接或唤醒后，急涨急跌规则会显示积累历史状态，覆盖完整窗口后才评估；不会用更老的稀疏样本冒充指定时间窗。

每条规则可以选择一次性或重复提醒、系统声音以及 1–1440 分钟冷却时间（默认 10 分钟）。一次性规则成功提交通知后自动暂停。重复规则只有先退出条件、再重新穿越且冷却已结束时才再次触发；冷却中的穿越不延迟补发。普通阈值规则首次取得新数据时只建立基线，不补发启用前已满足的条件。

第一次保存启用的规则时请求系统通知权限；拒绝后会保存为暂停状态，可在设置中允许通知后重新开启。通知页提供权限状态和“发送测试通知”。提醒只在应用运行时评估；收起菜单后仍继续监控，睡眠、退出或断网期间不补发未知行情。Perps 有需要价格的启用规则时会保留对应持仓的后台行情订阅；仅轮询模式继续遵循 Updates 的间隔，WebSocket 失联或静默时回退轮询。价格、清算距离与盈亏分别检查其依赖的数据时间，缓存与过期数据不会触发提醒。

**Settings → Notifications → Time Sensitive notifications / 即时通知** 默认开启并立即保存；关闭后使用普通通知。真实提醒和测试通知使用同一优先级。应用读取 macOS 的实际即时通知权限，并在该开关下方显示允许、关闭或不可用状态；开关开启本身不代表系统已经授权。

**当前公开 DMG 和默认本地构建使用临时签名，仍发送普通通知。** 应用会检查自身实际签名中的 entitlement；缺少该能力时显示“需要开发者签名”，自动使用普通优先级，保留即时通知偏好。启用该能力需要付费 Apple Developer 团队、有效证书和包含 `com.apple.developer.usernotifications.time-sensitive` 的配置文件；免费 Personal Team 不支持。仓库提供独立的 [`MarketCopilot-TimeSensitive.entitlements`](App/MarketCopilot-TimeSensitive.entitlements)，默认构建不依赖该权限，因此普通用户和 CI 仍能直接 Build。

具备上述团队、证书且已在 Xcode 登录开发者账户时，可以使用自动配置文件签名：

```sh
MARKETCOPILOT_DEVELOPMENT_TEAM=YOUR_TEAM_ID zsh Scripts/build.sh Release
```

此可选方式使用 Apple Development 证书和即时通知 entitlement。用 Xcode 界面构建时，选择相应付费团队、启用自动签名与 Time Sensitive Notifications capability，并将 `CODE_SIGN_ENTITLEMENTS` 设为 `App/MarketCopilot-TimeSensitive.entitlements`。开发证书与私钥留在本机 Keychain；不提交到仓库。公开 GitHub Actions 当前继续生成普通通知版 DMG。

要在专注模式期间收到提醒，请在 **系统设置 → 通知 → MarketCopilot** 允许通知及即时通知，并在当前 **专注模式 → 选项** 中允许即时通知；横幅样式和声音仍遵循系统设置。系统关闭即时通知时，提醒仍按系统规则处理，应用不会强行绕过。Apple 的 [Time Sensitive 说明](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive)明确由用户决定是否允许此类打断。**Critical Alerts / 重要警报** 是另一种级别，需要 [Apple 单独批准的 entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts)，本应用不申请或声称具备该权限。

规则通过 SwiftData 保存，并绑定 Predictions 钱包或 Perps 账户地址；未填写 Perps owner 时，使用已验证会话的公开 proxy 地址作为隔离标识。更换账户后旧规则暂停，账户断开或持仓不再活跃时，价格及盈亏规则暂停监控。历史规则仍可从通知设置管理，持仓再次活跃时重新建立基线。通知点击后打开对应的官方 Polymarket 页面。

## 金额口径

| 项目 | 来源 |
|---|---|
| Predictions Portfolio | Data API v2 `/v2/value`（包含官方组合持仓估值）+ Prediction Cash |
| Predictions Cash | 官方 pUSD 合约的链上余额；选填 CLOB 时优先使用其 collateral balance，失败回退链上读取；以官方 6 位基础单位换算 |
| Perps Portfolio | `margin.total_account_value`，已经是账户净值 |
| Perps Cash | `margin.available_order_margin`，不是 withdrawable |
| Position / Margin / Funding | 官方 `position_value` / `initial_margin` / `cumulative_funding` |

Perps 现金不会重复加到 Perps Portfolio；杠杆名义头寸只在 Position 显示。回报率使用官方 `return_on_equity × 100%`，不自行猜测分母。Funding 保留官方累计值及其符号。金额计算与解码使用 `Decimal`。

显示偏移的计算：`Predictions Cash / Portfolio 各加 Predictions offset`，`Perps Cash / Portfolio 各加 Perps offset`。合计 Cash 和合计 Portfolio 分别求和，因此每个总额都只包含一次对应的 offset。

## 验证

```sh
swift test                         # 确定性单元测试，不联网、不使用真实凭证
swift run market-probe              # 官方公共 API / WebSocket 只读连接检查
zsh Scripts/validate.sh             # 原生 Keychain / SwiftData / 布局检查及组件渲染
```

Debug 的 `--design-preview` 显式启用 Figma 样例；`--expanded` 展开抽屉，`--validate-motion` 记录原生窗口和抽屉的动画中间帧。外观始终实时跟随系统。样例不会作为联网失败后的备用数据，Release 不启用样例模式。组件渲染位于 `build/Validation/`；原生玻璃与桌面背景的最终合成需要在可见桌面上检查。

详细验收记录与测试映射见 [Docs/Validation.md](Docs/Validation.md)。

## Design reference

- [Menu states](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=2-4070)
- [Updated Perps drawer](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=2-4069)
- [Prediction drawer](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=10-138)
- [Head icons](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=1-3545)

实现按原生骨架、设计素材、菜单、设置、Prediction、Perps、实时协调、原生接线和验收分别提交。
