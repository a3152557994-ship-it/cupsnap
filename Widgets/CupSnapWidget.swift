import SwiftUI
import WidgetKit

struct CupSnapWidgetEntry: TimelineEntry {
    let date: Date
}

struct CupSnapWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CupSnapWidgetEntry {
        CupSnapWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CupSnapWidgetEntry) -> Void) {
        completion(CupSnapWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CupSnapWidgetEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 4, to: now) ?? now.addingTimeInterval(14400)
        completion(Timeline(entries: [CupSnapWidgetEntry(date: now)], policy: .after(next)))
    }
}

struct CupSnapWidgetView: View {
    var entry: CupSnapWidgetEntry
    @Environment(\.widgetFamily) var family

    private var isZh: Bool {
        (Locale.preferredLanguages.first ?? "zh").lowercased().hasPrefix("zh")
    }

    var body: some View {
        ZStack {
            Color(red: 0.980, green: 0.961, blue: 0.925)
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("🧋")
                            .font(.system(size: 26))
                        Spacer()
                        Text(isZh ? "贴一杯" : "CupSnap")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.478, green: 0.275, blue: 0.153))
                    }
                    Spacer()
                    Text(isZh ? "今天喝点什么？" : "Today's Sip?")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.239, green: 0.149, blue: 0.094))
                    Text(isZh ? "点一下拍杯变贴纸" : "Tap to snap sticker")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.545, green: 0.447, blue: 0.376))
                }
                .padding(14)
            } else {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isZh ? "贴一杯 · 饮品手账" : "CupSnap Sticker Diary")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.478, green: 0.275, blue: 0.153))
                        Text(isZh ? "拍杯子自动抠白边贴纸" : "Snap Boba & Coffee Stickers")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.239, green: 0.149, blue: 0.094))
                        Text(isZh ? "0广告 · 离线识小票 · 一键晒月报" : "Ad-Free · Offline OCR · Monthly Poster")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.545, green: 0.447, blue: 0.376))
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("🧋☕️🍵")
                            .font(.system(size: 22))
                        Text(isZh ? "+ 记一杯" : "+ Snap")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(red: 0.478, green: 0.275, blue: 0.153)))
                    }
                }
                .padding(16)
            }
        }
        .widgetURL(URL(string: "cupsnap://add"))
        .containerBackground(Color(red: 0.980, green: 0.961, blue: 0.925), for: .widget)
    }
}

@main
struct CupSnapWidgetBundle: WidgetBundle {
    var body: some Widget {
        CupSnapQuickWidget()
    }
}

struct CupSnapQuickWidget: Widget {
    let kind: String = "CupSnapQuickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CupSnapWidgetProvider()) { entry in
            CupSnapWidgetView(entry: entry)
        }
        .configurationDisplayName("贴一杯 · 饮品贴纸日历")
        .description("桌面一键拍下今日奶茶或咖啡，离线自动抠图变手账贴纸。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
