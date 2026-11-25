# 个人苹果号 APP ICP 备案 + 零风险多平台分发即用手册

> 更新时间：`2026-11-25` · 适用账号：`a3152557994@gmail.com`（个人开发者 `HE YANG / Yang He`，Team ID `KU364788TC`）

---

## 一、中国大陆区个人号 APP ICP 备案（一键复制参数表）

苹果个人开发者账号必须匹配**个人主体 APP ICP 备案**（切勿用公司主体去备案个人苹果号，否则 App Store Connect 校验报 `Provider name mismatch`）。

### 1. 本机正式发布证书（`Apple Distribution: Yang He (KU364788TC)`）提取参数
- **证书有效期**：`2026-09-24` 至 `2027-09-24`
- **签名指纹 SHA-1（去冒号连写版，腾讯云/阿里云默认填此项）**：
  `7184F55BE9EA59354D6249CA3037B946AE063B3F`
- **签名指纹 SHA-1（带冒号版）**：
  `71:84:F5:5B:E9:EA:59:35:4D:62:49:CA:30:37:B9:46:AE:06:3B:3F`
- **签名指纹 MD5（去冒号备用）**：
  `EEFD9004130D8AC24D8DA99813C2D2A5`
- **公钥（Modulus 512位十六进制，标准 iOS 公钥框直接粘贴）**：
  `BB1D0606924EEA6B85597B7FE26C2054B5980B0AEB970A10A1F71D33892C6A9A06A83D19B0892F87F886703A4514C6C12B32DBBFD30A57615972AB4B00E75F59C75701C5B93AC99A2B5DB4F2A6890BFBC944CB45F7FCA82184FBA497325371082174B889667DD5D953BCC04121C72AFD1434E6BE8991BDE7EC6E26EA0FF59A7B98DF8C57A259BB2C511E32F35366399B1B7330CCD1A16043FD167D44F35EA854217AD3904D6D3014F431294B93CE61309545B62784DD38C4127547CB33B6314A971E639B08D925BEEB4B667C5DFEFBE263AD8ECC0D803DF2AC601AEE7A18FF7057B0854580D50064949EB1E2C20EDB0A6820E0573D044AC809109C6AF6EFAC49`

### 2. 首批一次顺手绑定的 5 款主力 iOS 包名（1 台国内轻量云默认送 5 个备案服务号）
1. **配料照妖镜**：`com.yanghe.purescan`（纯本地离线食品与日化成分文字查询工具）
2. **净盾**：`com.yanghe.cleanshield`（纯本地离线浏览器清净与照片定位去除工具）
3. **贴一杯**：`com.yanghe.cupsnap`（纯本地离线日常饮品贴纸日历记录工具）
4. **等片相机**：`com.yanghe.waitcam`（纯本地离线复古胶片滤镜拍照工具）
5. **壳记**：`com.yanghe.snapframenotes`（纯本地离线手机截图边框美化工具）

> 💡 **个人备案过审秘诀**：服务内容勾选「生活服务 / 实用工具」，备注统一写清 **「纯单机离线个人实用小工具，无账号注册、无评论发帖、无社区交互、无经营性交易与信息发布」**，初审 1–2 天 + 工信部短信核验 + 管局约 7–12 个工作日下发 `京/浙/粤ICP备xxxxxxxx号-1A` 后，填入 App Store Connect 即可秒开大陆区下载。

---

## 二、小红书创服平台「互动小工具 `.zip`」上传与真机扫码核验指引

已按 `2026-11-25` 最新小红书容器规范打包并通过 `audit_artifact.py` 零错误门禁审计：
1. **贴一杯 · 奶茶咖啡贴纸手账日历**：`/Users/wang/OPC/projects/cupsnap/release/cupsnap-xhs-minitool.zip`（`8.7 KB`）
2. **配料照妖镜 · 配料表红黑榜避雷器**：`/Users/wang/OPC/projects/purescan/release/purescan-xhs-minitool.zip`（`9.2 KB`）

### 上传与三步必验提醒（规范要求）
1. 登录小红书创作服务平台 → **Builder Hub → 小工具**，上传上述生成的 `.zip` 包；
2. **先在创服平台 PC 模拟器**完成完整功能验证（选照片贴纸 / 切换忌口雷达 / 生成 3:4 海报）；
3. **再分别使用 Android 真机与 iOS 真机扫码**验证相同产物（重点确认右上角胶囊避让正常、点击「存相册」与「一键发笔记」拉起正常；未在 Chrome 61 旧内核与双端真机实测前标记为“待真机验证”）。

---

## 三、海外高权重免费软件导航站即贴文案（0 成本吃 Google 平替长尾词）

### 1. AlternativeTo.net（流量最精准的「高价订阅软件平替」搜索引擎）
- **FlatBill**（挂载为 `Invoice Simple`、`Joist`、`QuickBooks Self-Employed` 的 `One-Time Payment / Offline` 平替）：
  - URL: `https://a3152557994-ship-it.github.io/flatbill/`
  - Tagline: `Offline contractor estimate & invoice PDF maker with 0% payment fees and $19.99 lifetime buyout instead of $220/yr subscriptions.`
- **MileDeck**（挂载为 `MileIQ`、`Everlance`、`Hurdlr` 的离线买断平替）：
  - URL: `https://a3152557994-ship-it.github.io/miledeck/`
  - Tagline: `100% on-device automatic GPS mileage tracker with 2026 IRS split rates ($0.725/$0.76) and $14.99 one-time buyout.`
- **PureScan**（挂载为 `Yuka`、`Think Dirty` 的无需条形码离线平替）：
  - URL: `https://a3152557994-ship-it.github.io/purescan/`
  - Tagline: `Skip broken barcodes — scan any food, gout/purine, skincare INCI, or pet food ingredient label 100% offline in 0.3s with zero ads.`
