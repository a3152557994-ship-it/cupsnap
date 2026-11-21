import SwiftUI

struct CalendarWallView: View {
    @ObservedObject var store: DrinkStore
    @ObservedObject var l10n: L10n
    var onTapAdd: (Date) -> Void
    var onTapPoster: () -> Void

    @State private var selectedDay: Date = Date()
    @State private var editingEntry: DrinkEntry?

    private let weekdaysZh = ["一", "二", "三", "四", "五", "六", "日"]
    private let weekdaysEn = ["M", "T", "W", "T", "F", "S", "S"]

    private var stats: MonthlyDrinkStats {
        store.monthlyStats(for: store.selectedMonth)
    }

    private var dayEntries: [DrinkEntry] {
        store.entries(onDay: selectedDay)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CupTheme.paperBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    topHeaderBar
                    monthlySummaryStrip
                    calendarGridCard
                    selectedDaySection
                    if store.hasSampleEntries {
                        sampleNoticeBanner
                    }
                    Spacer(minLength: 112)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            // 右下角「贴一杯」主行动悬浮按钮
            Button {
                onTapAdd(selectedDay)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 18, weight: .bold))
                    Text(l10n.t("贴一杯", "Snap Cup"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [CupTheme.caramel, Color(hex: "9A5831")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: CupTheme.caramel.opacity(0.36), radius: 12, x: 0, y: 6)
                )
            }
            .padding(.trailing, 18)
            .padding(.bottom, 10)
        }
        .sheet(item: $editingEntry) { entry in
            AddDrinkSheet(store: store, l10n: l10n, initialDate: entry.date, editingEntry: entry)
        }
    }

    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(l10n.t("贴一杯", "CupSnap"))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(CupTheme.cocoaInk)
                    Text(l10n.t("0广告", "Ad-Free"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.matcha)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(CupTheme.matcha.opacity(0.14)))
                }
                Text(l10n.t("拍照秒抠白边贴纸 · 离线识小票", "Offline Cutout Stickers & Receipt OCR"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CupTheme.mutedBrown)
            }

            Spacer()

            // 月份切换胶囊
            HStack(spacing: 6) {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CupTheme.cocoaInk)
                        .frame(width: 26, height: 26)
                }
                Text(monthTitle(store.selectedMonth))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                    .monospacedDigit()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CupTheme.cocoaInk)
                        .frame(width: 26, height: 26)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(CupTheme.cardBg)
                    .overlay(Capsule().stroke(CupTheme.borderLine, lineWidth: 1))
            )
        }
    }

    private var monthlySummaryStrip: some View {
        HStack(spacing: 10) {
            summaryChip(
                icon: "cup.and.saucer.fill",
                tint: CupTheme.caramel,
                value: "\(stats.totalCups)",
                label: l10n.t("本月杯数", "Cups")
            )
            summaryChip(
                icon: "yensign.circle.fill",
                tint: CupTheme.berry,
                value: String(format: l10n.isZh ? "¥%.0f" : "$%.0f", stats.totalSpend),
                label: l10n.t("续命花费", "Spent")
            )
            summaryChip(
                icon: "bolt.heart.fill",
                tint: CupTheme.matcha,
                value: "\(stats.totalCaffeineMg)mg",
                label: l10n.t("咖啡因", "Caffeine")
            )
            Button(action: onTapPoster) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.t("晒月报", "Poster"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 64, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [CupTheme.berry, Color(hex: "F08D7E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
        }
    }

    private func summaryChip(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CupTheme.mutedBrown)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CupTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1))
        )
    }

    private var calendarGridCard: some View {
        let cells = buildMonthCells(for: store.selectedMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 10) {
            // 星期标题栏
            HStack(spacing: 4) {
                ForEach(Array((l10n.isZh ? weekdaysZh : weekdaysEn).enumerated()), id: \.offset) { _, dayStr in
                    Text(dayStr)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.mutedBrown)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(cells) { cell in
                    if let date = cell.date {
                        dayCellView(date: date)
                    } else {
                        Color.clear.frame(height: 62)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CupTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1.2))
                .shadow(color: CupTheme.cocoaInk.opacity(0.05), radius: 14, x: 0, y: 6)
        )
    }

    private func dayCellView(date: Date) -> some View {
        let cal = Calendar.current
        let dayNum = cal.component(.day, from: date)
        let items = store.entries(onDay: date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDay)
        let isToday = cal.isDateInToday(date)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedDay = date
            }
            if items.isEmpty {
                onTapAdd(date)
            }
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isSelected ? Color(hex: "F5E8D6") : (items.isEmpty ? Color(hex: "FAF6F0") : Color(hex: "FFF9F0")))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(isSelected ? CupTheme.caramel : (isToday ? CupTheme.berry.opacity(0.6) : Color.clear), lineWidth: isSelected ? 1.8 : 1.2)
                    )

                Text("\(dayNum)")
                    .font(.system(size: 10, weight: isToday || isSelected ? .heavy : .semibold, design: .rounded))
                    .foregroundStyle(isToday ? CupTheme.berry : CupTheme.mutedBrown)
                    .padding(.top, 4)
                    .padding(.leading, 5)

                if let first = items.first {
                    VStack {
                        Spacer(minLength: 10)
                        CupStickerArtView(
                            preset: first.presetCup,
                            frameStyle: first.frameStyle,
                            customImage: store.loadCustomSticker(fileName: first.customStickerFileName),
                            brandShort: first.brand,
                            size: 48,
                            tilt: first.tiltDegrees
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if items.count > 1 {
                        Text("+\(items.count - 1)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(CupTheme.berry))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(3)
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CupTheme.borderLine)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 10)
                }
            }
            .frame(height: 64)
        }
        .buttonStyle(.plain)
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(daySectionTitle(selectedDay))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Spacer()
                Button {
                    onTapAdd(selectedDay)
                } label: {
                    Label(l10n.t("再贴一杯", "Add Cup"), systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.caramel)
                }
            }

            if dayEntries.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 22))
                        .foregroundStyle(CupTheme.mutedBrown.opacity(0.6))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.t("这天还没贴杯子贴纸", "No cup sticker on this day yet"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CupTheme.cocoaInk)
                        Text(l10n.t("点右下角「贴一杯」拍杯子或小票 3 秒记录", "Tap Snap Cup to auto-cutout or scan receipt"))
                            .font(.system(size: 12))
                            .foregroundStyle(CupTheme.mutedBrown)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(CupTheme.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1))
                )
            } else {
                ForEach(dayEntries) { entry in
                    drinkDetailRow(entry)
                }
            }
        }
    }

    private func drinkDetailRow(_ entry: DrinkEntry) -> some View {
        HStack(spacing: 12) {
            CupStickerArtView(
                preset: entry.presetCup,
                frameStyle: entry.frameStyle,
                customImage: store.loadCustomSticker(fileName: entry.customStickerFileName),
                brandShort: entry.brand,
                size: 62,
                tilt: entry.tiltDegrees * 0.6
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.brand)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: entry.category.badgeColorHex))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: entry.category.badgeColorHex).opacity(0.13)))
                    Text(entry.drinkName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.cocoaInk)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: l10n.isZh ? "¥%.1f" : "$%.1f", entry.price))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(CupTheme.caramel)
                        .monospacedDigit()
                }

                HStack(spacing: 6) {
                    tagPill(entry.sugar.title(l10n.isZh))
                    tagPill(entry.ice.title(l10n.isZh))
                    tagPill("\(entry.caffeineMg)mg")
                    Spacer()
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= entry.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(i <= entry.rating ? CupTheme.warmGold : CupTheme.borderLine)
                        }
                    }
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 12))
                        .foregroundStyle(CupTheme.mutedBrown)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CupTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1))
        )
        .onTapGesture {
            editingEntry = entry
        }
        .contextMenu {
            Button { editingEntry = entry } label: {
                Label(l10n.t("编辑这杯", "Edit"), systemImage: "pencil")
            }
            Button(role: .destructive) {
                store.deleteEntry(entry)
            } label: {
                Label(l10n.t("撕掉贴纸", "Delete"), systemImage: "trash")
            }
        }
    }

    private func tagPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(CupTheme.mutedBrown)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color(hex: "F3EAE0")))
    }

    private var sampleNoticeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(CupTheme.caramel)
            Text(l10n.t("当前含演示贴纸预览效果，随时一键清空开始记你的真实杯子", "Showing sample stickers for preview. Clear anytime to start fresh."))
                .font(.system(size: 12))
                .foregroundStyle(CupTheme.mutedBrown)
            Spacer()
            Button(l10n.t("清空演示", "Clear")) {
                withAnimation { store.clearSampleEntries() }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(CupTheme.berry)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "F5EBDC"))
        )
    }

    private func shiftMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: store.selectedMonth) {
            withAnimation {
                store.selectedMonth = next
            }
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = l10n.isZh ? "yyyy年M月" : "MMM yyyy"
        return df.string(from: date)
    }

    private func daySectionTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = l10n.isZh ? "M月d日 饮品手账" : "MMM d · Cup Log"
        return df.string(from: date)
    }

    private struct CalendarCell: Identifiable {
        let id: String
        let date: Date?
    }

    private func buildMonthCells(for monthDate: Date) -> [CalendarCell] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else {
            return []
        }
        // 周一为第一列 (weekday: 1=Sun, 2=Mon...7=Sat -> 0=Mon...6=Sun)
        let rawWeekday = cal.component(.weekday, from: firstDay)
        let leadingBlanks = (rawWeekday + 5) % 7

        var result: [CalendarCell] = []
        for idx in 0..<leadingBlanks {
            result.append(CalendarCell(id: "blank-\(idx)", date: nil))
        }
        for day in range {
            let d = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: day, hour: 12))
            result.append(CalendarCell(id: "day-\(comps.year ?? 0)-\(comps.month ?? 0)-\(day)", date: d))
        }
        return result
    }
}
