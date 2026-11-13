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

## 连接账户

点击菜单栏的 Portfolio / Cash → Settings → Account：

1. **Account wallet**：从 Polymarket 个人菜单复制账户钱包地址。
2. **Signer address / Wallet type**：填写 CLOB 凭证对应的签名者与钱包类型。新 Deposit Wallet 与旧 Proxy / Safe 不同；签名者地址也可能不同于账户钱包。
3. **Predictions**：填写官方 CLOB L2 的 API key、secret、passphrase。不要填 Builder 或 Relayer 的 key。
4. **Perps**：填写官方 Perps delegated session 的 proxy address 和 secret；可额外填写预期账户 owner，防止导入其他账户的凭证。
5. 点击 **Save & Connect**；Updates 页显示各数据源的连接状态。

凭证创建方式见 [CLOB 官方认证指南](https://docs.polymarket.com/getting-started/api#authentication) 与 [Perps 官方 session 指南](https://docs.polymarket.com/perps/authenticated-sessions)。本应用导入现有凭证，不创建交易授权、不接收钱包私钥。

仅填公开钱包地址也可以保存，但官方私有现金和 Perps 明细仍需上述凭证。缺失数据显示 `—`；不会用零或示例数据补齐。

## 使用与更新

- 菜单栏持续显示两类资产的合计 Portfolio 与合计 Cash。
- 打开菜单或展开 Perps 抽屉会立即请求最新数据；抽屉中直接显示全部持仓及六项明细。
- 点击行情数值可通过悬停说明查看 mark / bid / ask。原稿 `Liq. price` 表示清算价。
- Updates 可分别选择 WebSocket 优先或仅轮询，设置 1–300 秒轮询间隔和 10–600 秒校准间隔。
- 官方 Perps 账户推送约每 5 秒一次；行情推送可以更快，画面合并到最多每秒 4 次，避免数字动画反复打断。
- 关闭菜单后继续更新；休眠暂停，唤醒和网络恢复后重新同步。断线、限流及凭证过期会在悬停说明和设置中显示，保留最后有效值及时间。
- General 可设置开机启动、断开账户或退出。断开账户删除本机凭证与对应资产缓存，不影响 Polymarket 账户。

## 金额口径

| 项目 | 来源 |
|---|---|
| Predictions Portfolio | Data API v2 `/v2/value`（包含官方组合持仓估值）+ Prediction Cash |
| Predictions Cash | CLOB collateral balance，以官方 6 位基础单位换算 |
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

Debug 的 `--design-preview` 显式启用 Figma 样例；`--expanded` 展开抽屉，`--light` / `--dark` 指定该进程的外观。样例不会作为联网失败后的备用数据，Release 不启用样例模式。组件渲染位于 `build/Validation/`；原生玻璃与桌面背景的最终合成需要在可见桌面上检查。

详细验收记录与测试映射见 [Docs/Validation.md](Docs/Validation.md)。

## Design reference

- [Menu states](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=2-4070)
- [Head icons](https://www.figma.com/design/6NDdW5dL54pCEkG3juc8TR/Untitled?node-id=1-3545)

实现按原生骨架、设计素材、菜单、设置、Prediction、Perps、实时协调、原生接线和验收分别提交。
