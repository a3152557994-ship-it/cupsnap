import Photos
import SwiftUI
import UIKit

/// 小红书 3:4 爆款「月度续命饮品贴纸手账海报」工作室
struct PosterStudioView: View {
    @ObservedObject var store: DrinkStore
    @ObservedObject var l10n: L10n

    @State private var theme: PosterTheme = .caramelCream
    @State private var savedToast: String? = nil
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false

    private var monthEntries: [DrinkEntry] {
        store.entries(inMonth: store.selectedMonth)
    }

    private var stats: MonthlyDrinkStats {
        store.monthlyStats(for: store.selectedMonth)
    }

    var body: some View {
        ZStack {
            CupTheme.paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerBar
                    themePickerRow
                    posterCanvas
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: CupTheme.cocoaInk.opacity(0.14), radius: 18, x: 0, y: 10)
                    actionButtonsRow

                    if let savedToast {
                        Text(savedToast)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(CupTheme.matcha)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(CupTheme.matcha.opacity(0.15)))
                    }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage])
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("月度晒图海报", "Monthly Poster"))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Text(l10n.t("3:4 黄金比例 · 无水印一键发小红书/朋友圈", "3:4 Aesthetic Ratio · Ready to Share"))
                    .font(.system(size: 12))
                    .foregroundStyle(CupTheme.mutedBrown)
            }
            Spacer()
        }
    }

    private var themePickerRow: some View {
        HStack(spacing: 8) {
            ForEach(PosterTheme.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.25)) { theme = item }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: item.accentHex))
                            .frame(width: 12, height: 12)
                        Text(item.title(l10n.isZh))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(theme == item ? .white : CupTheme.cocoaInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(theme == item ? Color(hex: item.accentHex) : CupTheme.cardBg)
                            .overlay(Capsule().stroke(CupTheme.borderLine, lineWidth: theme == item ? 0 : 1))
                    )
                }
            }
        }
    }

    private var posterCanvas: some View {
        let persona = store.personalityTitle(for: stats, isZh: l10n.isZh)
        let accent = Color(hex: theme.accentHex)
        let chipBg = Color(hex: theme.chipHex)

        return VStack(spacing: 14) {
            // 顶部手账抬头
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monthEnglishTag(store.selectedMonth))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(accent.opacity(0.75))
                    Text(l10n.t("\(monthNum(store.selectedMonth))月续命饮品手账", "Monthly Sip Diary"))
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                        .foregroundStyle(accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.totalCups)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .monospacedDigit()
                    Text(l10n.t("本月贴纸杯", "CUPS"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accent.opacity(0.7))
                }
            }

            // 专属续命称号徽章
            HStack(spacing: 10) {
                Text("🏆")
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(accent)
                    Text(persona.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(accent.opacity(0.8))
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(chipBg))

            // 核心贴纸墙拼贴（最多展示 12 张最精华贴纸）
            let displayItems = Array(monthEntries.prefix(12))
            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            VStack(spacing: 8) {
                if displayItems.isEmpty {
                    Text(l10n.t("快去贴下你本月的第一杯奶茶或咖啡吧 🧋", "Snap your first cup to fill this sticker wall 🧋"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.65))
                        .frame(height: 150)
                } else {
                    LazyVGrid(columns: cols, spacing: 10) {
                        ForEach(displayItems) { entry in
                            VStack(spacing: 2) {
                                CupStickerArtView(
                                    preset: entry.presetCup,
                                    frameStyle: entry.frameStyle,
                                    customImage: store.loadCustomSticker(fileName: entry.customStickerFileName),
                                    brandShort: entry.brand,
                                    size: 56,
                                    tilt: entry.tiltDegrees
                                )
                                Text(entry.drinkName)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(accent.opacity(0.85))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )

            // 底部 3 格数据汇总
            HStack(spacing: 8) {
                posterStatBox(
                    title: l10n.t("总花费", "SPENT"),
                    value: String(format: l10n.isZh ? "¥%.0f" : "$%.0f", stats.totalSpend),
                    accent: accent,
                    bg: chipBg
                )
                posterStatBox(
                    title: l10n.t("最爱品牌", "TOP BRAND"),
                    value: stats.topBrand,
                    accent: accent,
                    bg: chipBg
                )
                posterStatBox(
                    title: l10n.t("偏爱糖度", "SUGAR"),
                    value: stats.favoriteSugar.shortLabel,
                    accent: accent,
                    bg: chipBg
                )
            }

            // 极简品牌角标（天然小红书自传播钩子）
            HStack {
                Text(l10n.t("贴一杯 CupSnap · 0广告拍照抠图贴纸日历", "CupSnap · Offline Drink Sticker Calendar"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent.opacity(0.6))
                Spacer()
                Text("☕️ \(stats.totalCaffeineMg)mg")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accent.opacity(0.7))
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(Color(hex: theme.bgHex))
    }

    private func posterStatBox(title: String, value: String, accent: Color, bg: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(bg))
    }

    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Button {
                savePosterToPhotos()
            } label: {
                Label(l10n.t("存高清海报到相册", "Save to Photos"), systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(CupTheme.caramel))
            }

            Button {
                if let img = renderPosterImage() {
                    shareImage = img
                    showShareSheet = true
                }
            } label: {
                Label(l10n.t("分享", "Share"), systemImage: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.caramel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(CupTheme.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(CupTheme.caramel, lineWidth: 1.5))
                    )
            }
        }
    }

    @MainActor
    private func renderPosterImage() -> UIImage? {
        let renderer = ImageRenderer(content: posterCanvas.frame(width: 390))
        renderer.scale = 3.0
        return renderer.uiImage
    }

    @MainActor
    private func savePosterToPhotos() {
        guard let img = renderPosterImage() else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        withAnimation {
            savedToast = l10n.t("已保存高清 3:4 海报到系统相册，快去发小红书吧 ✨", "Saved high-res poster to Photos ✨")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { savedToast = nil }
        }
    }

    private func monthNum(_ d: Date) -> Int {
        Calendar.current.component(.month, from: d)
    }

    private func monthEnglishTag(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMMM yyyy · CUPSNAP"
        return df.string(from: d).uppercased()
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
