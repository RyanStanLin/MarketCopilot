# MarketCopilot

原生 macOS 27 菜单栏应用，分别查看 Polymarket Predictions 与 Perps 的资产、现金和永续持仓。

采用 SwiftUI、AppKit、SwiftData 和官方 Polymarket REST / WebSocket，无第三方依赖。API 凭证仅保存到 macOS Keychain，不需要钱包私钥。

## Build

需要 Xcode 27 / Swift 6.4。打开 `MarketCopilot.xcodeproj`，或运行：

```sh
zsh Scripts/build.sh Debug
zsh Scripts/build.sh Release
```

应用位于 `build/Build/Products/Debug/MarketCopilot.app` 或 `build/Build/Products/Release/MarketCopilot.app`。脚本为本机架构构建并本地签名；可直接运行。分发给其他 Mac 的 Developer ID 签名和公证需要另行配置证书。

安装本机发行版：`zsh Scripts/install.sh`。默认安装到 `/Applications/MarketCopilot.app` 并打开设置；已有版本先备份到 `~/Library/Application Support/MarketCopilot/Previous Versions/`，账户数据和 Keychain 不会被删除。

## 连接账户

点击菜单栏的 Portfolio / Cash → Settings → Account：

1. **Predictions → Wallet or profile**：粘贴账户钱包地址、`@用户名` 或 Polymarket 个人主页链接。Google / 邮箱登录账户同样适用，不需要 CLOB key 或钱包签名。用户名通过官方 Gamma API 精确匹配；无法唯一匹配时使用个人菜单中的账户钱包地址。
2. **Perps**：填写官方 Perps delegated session 的 proxy address 和 secret；可额外填写预期账户 owner。只连接 Perps 时可留空 Predictions；应用会从官方凭证接口确认 owner。
3. 点击 **Save & Connect**；Updates 页显示各数据源的连接状态。

Predictions 使用官方公开 Data / Gamma API，并通过 Polygon 官方文档列出的公共 RPC，读取 Polymarket 官方 pUSD 合约的 `balanceOf`；请求只包含 `eth_chainId` / `eth_call`，不创建授权、不提交交易。合约与网络配置在 `Sources/MarketCore/Resources/Endpoints.json`。见 [官方钱包说明](https://docs.polymarket.com/trading/wallets-auth)、[pUSD 合约](https://docs.polymarket.com/resources/contracts) 和 [Polygon RPC](https://docs.polygon.technology/pos/reference/rpc-endpoints)。

已有 CLOB L2 凭证可在折叠的 **Advanced Predictions access** 中选填，用于私有订单/成交通知；正常读取资产和现金不依赖这些凭证。Perps 明细仍需要 [官方 session 凭证](https://docs.polymarket.com/perps/authenticated-sessions)。单个来源尚未配置或不可用时，菜单栏汇总已有来源；只有完全没有可用数据时才显示 `—`。悬停说明会标明汇总包含的可用部分。

## 使用与更新

- 菜单栏持续显示两类资产的合计 Portfolio 与合计 Cash。
- 打开菜单或展开 Perps 抽屉会立即请求最新数据；抽屉中直接显示全部持仓及六项明细。
- 持仓更新保留已有显示顺序，新持仓追加到底部；关闭后移除。图标固定为 32×32。标题箭头按标记价相对入场价显示上涨/下跌，点击整张持仓打开 Polymarket Perps。
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
