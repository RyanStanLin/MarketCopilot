# MarketCopilot

原生 macOS 27 菜单栏应用，分别查看 Polymarket Predictions 与 Perps 的资产、现金和永续持仓。

采用 SwiftUI、AppKit、SwiftData 和官方 Polymarket REST / WebSocket，无第三方依赖。API 凭证仅保存到 macOS Keychain，不需要钱包私钥。

## Build

需要运行 macOS 27 或更高版本的 Mac，以及 Xcode 27 / Swift 6.4 或更新版本。本机脚本构建当前 Mac 的架构，GitHub Actions 生成 Apple Silicon 安装包。项目不依赖 Homebrew、CocoaPods 或其他第三方 Swift 包。

从 GitHub 下载源码，或在仓库创建后克隆，再打开 `MarketCopilot.xcodeproj`。选择 MarketCopilot scheme 和 My Mac 后运行；也可以在源码目录运行：

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

## 每次 push 自动生成安装包

[`.github/workflows/build-dmg.yml`](.github/workflows/build-dmg.yml) 监听所有分支和 tag 的每次 push，也支持 Actions 页手动运行。流程在 GitHub 的 `xcode-27` runner 上选择 Xcode 27 或更新版本，编译 Release、创建 DMG，并上传 DMG 与 SHA-256。每次运行独立保留产物，不会因为后续 push 而取消前一次构建。

下载位置：GitHub 仓库 → **Actions** → **Build DMG** → 对应运行 → **Artifacts**。产物保留 30 天；工作流无需配置账户 API 密钥或其他仓库 Secret，不会自动发布 GitHub Release。GitHub runner 和 Actions 版本依据[官方 runner 列表](https://github.com/actions/runner-images)与 [artifact 文档](https://github.com/actions/upload-artifact)配置。

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
- 打开菜单或展开 Perps 抽屉会立即请求最新数据；抽屉中直接显示全部持仓及六项明细。
- 持仓更新保留已有显示顺序，新持仓追加到底部；关闭后移除。图标固定为 32×32。标题箭头使用官方未实现收益 `unrealized_pnl` 的正负：非负向上、负数向下，随持仓更新切换；点击整张持仓打开 Polymarket Perps。
- 抽屉使用系统 `.fill.quaternary` 背景，实时适应深浅外观。远程图标先生成完整的固定方形位图；DOGE 这类内嵌 PNG 的简单 SVG 包装会先解包，避免只显示局部图案。
- General / 通用 → Language / 语言：支持跟随系统、English、简体中文与繁體中文，选择后立即生效并保存。
- General / 通用 → Cash offset / 现金偏移：输入 `-500`、`+10` 或普通小数，点击应用或按回车。合计 Cash = 已知来源的 Cash 总和 + offset；不修改 Predictions / Perps 原始余额或 Portfolio。该设置自动保存，不需要重新连接账户。尚无任何余额数据时仍显示 `—`，offset 不会伪装成真实余额。
- 点击行情数值可通过悬停说明查看 mark / bid / ask。原稿 `Liq. price` 表示清算价。
- Updates 可分别选择 WebSocket 优先或仅轮询，设置 1–300 秒轮询间隔和 10–600 秒校准间隔。
- 官方 Perps 账户推送约每 5 秒一次；行情推送可以更快，画面合并到最多每秒 4 次，避免数字动画反复打断。
- 关闭菜单后继续更新；休眠暂停，唤醒和网络恢复后重新同步。断线、限流及凭证过期会在悬停说明和设置中显示，保留最后有效值及时间。
- General 可设置开机启动、断开账户或退出。断开账户删除本机凭证与对应资产缓存，不影响 Polymarket 账户。

## 金额口径

| 项目 | 来源 |
|---|---|
| Predictions Portfolio | Data API v2 `/v2/value`（包含官方组合持仓估值）+ Prediction Cash |
| Predictions Cash | 官方 pUSD 合约的链上余额；选填 CLOB 时优先使用其 collateral balance，失败回退链上读取；以官方 6 位基础单位换算 |
| Perps Portfolio | `margin.total_account_value`，已经是账户净值 |
| Perps Cash | `margin.available_order_margin`，不是 withdrawable |
| Position / Margin / Funding | 官方 `position_value` / `initial_margin` / `cumulative_funding` |

Perps 现金不会重复加到 Perps Portfolio；杠杆名义头寸只在 Position 显示。回报率使用官方 `return_on_equity × 100%`，不自行猜测分母。Funding 保留官方累计值及其符号。金额计算与解码使用 `Decimal`。

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
- [Head icons](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=1-3545)

实现按原生骨架、设计素材、菜单、设置、Prediction、Perps、实时协调、原生接线和验收分别提交。
