import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct InsightsView: View {
    @ObservedObject var store: DrinkStore
    @ObservedObject var l10n: L10n
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDocument: BackupTextDocument?
    @State private var exportFileName: String = "CupSnap_Backup.json"
    @State private var exportContentType: UTType = .json
    @State private var feedbackMessage: String? = nil

    private var stats: MonthlyDrinkStats {
        store.monthlyStats(for: store.selectedMonth)
    }

    var body: some View {
        ZStack {
            CupTheme.paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    overviewMetricsCard
                    brandRankingCard
                    sugarBreakdownCard
                    dataSafetyBackupCard
                    reviewFunnelCard
                    studioMoreAppsCard
                    aboutAppCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success:
                feedbackMessage = l10n.t("备份文件已导出，换手机永不丢记录 ✅", "Backup exported safely ✅")
            case .failure:
                feedbackMessage = l10n.t("已取消导出", "Export cancelled")
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    let count = store.importBackupJSON(data)
                    feedbackMessage = l10n.t("成功恢复 \(count) 条饮品贴纸记录 🎉", "Restored \(count) drink records 🎉")
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("饮品账单与备份", "Stats & Backup"))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Text(l10n.t("纯免费 · 0 广告 · 数据完全掌握在你自己手里", "100% Free · Ad-Free · Local Privacy First"))
                    .font(.system(size: 12))
                    .foregroundStyle(CupTheme.mutedBrown)
            }
            Spacer()
        }
    }

    private var overviewMetricsCard: some View {
        let avgPrice = stats.totalCups > 0 ? stats.totalSpend / Double(stats.totalCups) : 0
        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                statBlock(title: l10n.t("本月杯数", "Cups"), value: "\(stats.totalCups)", sub: l10n.t("累计 \(store.entries.count) 杯", "Total \(store.entries.count)"))
                statBlock(title: l10n.t("本月消费", "Monthly Spend"), value: String(format: l10n.isZh ? "¥%.1f" : "$%.1f", stats.totalSpend), sub: String(format: l10n.isZh ? "杯均 ¥%.1f" : "Avg $%.1f", avgPrice))
            }
            HStack(spacing: 10) {
                statBlock(title: l10n.t("估算咖啡因", "Est. Caffeine"), value: "\(stats.totalCaffeineMg) mg", sub: l10n.t("健康参考日均 ≤400mg", "Ref ≤400mg/day"))
                statBlock(title: l10n.t("估算热量", "Est. Calories"), value: "\(stats.totalCaloriesKcal) kcal", sub: l10n.t("最常选 \(stats.favoriteSugar.title(true))", "Top: \(stats.favoriteSugar.shortLabel)"))
            }
        }
    }

    private func statBlock(title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CupTheme.mutedBrown)
            Text(value)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)
                .monospacedDigit()
            Text(sub)
                .font(.system(size: 11))
                .foregroundStyle(CupTheme.caramel.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardSurface)
    }

    private var brandRankingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l10n.t("本月回购 TOP 品牌", "Top Brands This Month"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)

            if stats.topBrands.isEmpty {
                Text(l10n.t("暂无记录，去贴下第一杯吧", "No drinks logged this month yet"))
                    .font(.system(size: 13))
                    .foregroundStyle(CupTheme.mutedBrown)
            } else {
                let maxCount = max(1, stats.topBrands.first?.1 ?? 1)
                ForEach(Array(stats.topBrands.prefix(5).enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 10) {
                        Text("#\(idx + 1)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(idx == 0 ? CupTheme.berry : CupTheme.mutedBrown)
                            .frame(width: 24, alignment: .leading)
                        Text(item.0)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(CupTheme.cocoaInk)
                            .frame(width: 96, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(idx == 0 ? CupTheme.caramel : CupTheme.matcha.opacity(0.72))
                                .frame(width: max(18, geo.size.width * CGFloat(item.1) / CGFloat(maxCount)), height: 10)
                                .padding(.top, 5)
                        }
                        .frame(height: 20)
                        Text(l10n.t("\(item.1)杯", "\(item.1)"))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(CupTheme.cocoaInk)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(15)
        .background(cardSurface)
    }

    private var sugarBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(l10n.t("品类分布", "Drink Categories"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)

            HStack(spacing: 8) {
                ForEach(DrinkCategory.allCases) { cat in
                    let count = stats.categoryBreakdown[cat] ?? 0
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: cat.badgeColorHex))
                        Text(cat.title(l10n.isZh))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CupTheme.mutedBrown)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: cat.badgeColorHex).opacity(0.1)))
                }
            }
        }
        .padding(15)
        .background(cardSurface)
    }

    // 针对竞品「卸载数据全没」差评，提供一键完整 JSON/CSV 本地备份与恢复
    private var dataSafetyBackupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(l10n.t("永不丢数据 · 本地备份中心", "Zero Data Loss · Local Backup"), systemImage: "externaldrive.badge.checkmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Spacer()
            }
            Text(l10n.t("无需注册账号、不依赖第三方服务器。随时把账单和贴纸记录存到 iCloud 云盘或导出 Excel 表格。", "No account required. Export JSON backup to iCloud Drive or CSV spreadsheet anytime."))
                .font(.system(size: 12))
                .foregroundStyle(CupTheme.mutedBrown)

            HStack(spacing: 8) {
                Button {
                    if let data = store.exportBackupJSON(), let str = String(data: data, encoding: .utf8) {
                        exportDocument = BackupTextDocument(text: str)
                        exportFileName = "CupSnap_Backup.json"
                        exportContentType = .json
                        showExporter = true
                    }
                } label: {
                    Label(l10n.t("导出备份", "Export JSON"), systemImage: "arrow.up.doc.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(CupTheme.matcha))
                }

                Button {
                    showImporter = true
                } label: {
                    Label(l10n.t("恢复备份", "Import"), systemImage: "arrow.down.doc.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CupTheme.matcha)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(CupTheme.matcha.opacity(0.14)))
                }

                Button {
                    let csv = store.exportCSVString(isZh: l10n.isZh)
                    exportDocument = BackupTextDocument(text: csv)
                    exportFileName = "CupSnap_Drinks.csv"
                    exportContentType = .commaSeparatedText
                    showExporter = true
                } label: {
                    Label("CSV", systemImage: "tablecells")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CupTheme.caramel)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3E5D4")))
                }
            }

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(CupTheme.matcha)
            }
        }
        .padding(15)
        .background(cardSurface)
    }

    private var reviewFunnelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.t("觉得「贴一杯」顺手吗？", "Enjoying CupSnap?"), systemImage: "heart.circle.fill")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)
            Text(l10n.t("独立开发者坚持 0 广告纯免费。你的一个五星好评，能帮更多爱喝奶茶咖啡的朋友搜到它！", "Zero ads & 100% free. Your quick 5-star rating helps fellow boba & coffee lovers discover CupSnap!"))
                .font(.system(size: 12))
                .foregroundStyle(CupTheme.mutedBrown)
            HStack(spacing: 8) {
                Button {
                    requestReview()
                    if let url = URL(string: "https://apps.apple.com/app/id6837625024?action=write-review") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            openURL(url)
                        }
                    }
                } label: {
                    Label(l10n.t("给个五星鼓励 ★", "Rate 5 Stars ★"), systemImage: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(CupTheme.caramel))
                }

                Button {
                    if let mail = URL(string: "mailto:a3152557994@gmail.com?subject=CupSnap%20Feedback") {
                        openURL(mail)
                    }
                } label: {
                    Label(l10n.t("提建议/加品牌", "Feedback"), systemImage: "envelope.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CupTheme.caramel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3E5D4")))
                }
            }
        }
        .padding(15)
        .background(cardSurface)
    }

    private var studioMoreAppsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.t("同作者 0 广告离线精品工具", "More Ad-Free Offline Apps"), systemImage: "sparkles")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)

            studioAppRow(
                emoji: "🔍",
                title: l10n.t("配料照妖镜 PureScan", "PureScan: Ingredient OCR"),
                sub: l10n.t("不用条形码 · 0.3秒离线拍奶茶零食与猫粮配料避雷", "Scan food, skincare & pet labels 100% offline"),
                urlStr: "https://apps.apple.com/app/id6837347918"
            )
            studioAppRow(
                emoji: "🛡️",
                title: l10n.t("净盾 CleanShield", "CleanShield: Safari & EXIF"),
                sub: l10n.t("Safari 零权限网页去广告 · 发原图前一键抹除 GPS 定位", "Zero-permission Safari blocker & Photo GPS scrubber"),
                urlStr: "https://apps.apple.com/app/id6836843272"
            )
            studioAppRow(
                emoji: "🎞️",
                title: l10n.t("等片相机 WaitCam", "WaitCam: 12h Film Camera"),
                sub: l10n.t("拍完锁进暗房 12 小时后开盲盒 · 派对强闪复古胶片", "Shoot tonight, reveal tomorrow retro disposable cam"),
                urlStr: "https://apps.apple.com/app/id6837624010"
            )
        }
        .padding(15)
        .background(cardSurface)
    }

    private func studioAppRow(emoji: String, title: String, sub: String, urlStr: String) -> some View {
        Button {
            if let u = URL(string: urlStr) { openURL(u) }
        } label: {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "F5ECE0")))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CupTheme.cocoaInk)
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(CupTheme.mutedBrown)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(CupTheme.caramel)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(CupTheme.paperBg.opacity(0.7)))
        }
        .buttonStyle(.plain)
    }

    private var aboutAppCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(l10n.t("界面语言 / Language", "Language"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CupTheme.cocoaInk)
                Spacer()
                Picker("", selection: $l10n.lang) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            Divider().overlay(CupTheme.borderLine)

            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.t("贴一杯 CupSnap v1.0.1 · 独立开发者匠心打造", "CupSnap v1.0.1 · Crafted Independently"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CupTheme.cocoaInk)
                Text(l10n.t("承诺：当前全功能免费、0 开屏广告、离线 AI 抠图与小票识别，照片绝不上传任何云端服务器。", "Promise: Full features free, zero ads, 100% on-device Vision AI cutout & OCR."))
                    .font(.system(size: 12))
                    .foregroundStyle(CupTheme.mutedBrown)
            }
        }
        .padding(15)
        .background(cardSurface)
    }

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(CupTheme.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1))
    }
}

struct BackupTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText, .plainText] }
    var text: String

    init(text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(data: data, encoding: .utf8) ?? ""
        } else {
            self.text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
