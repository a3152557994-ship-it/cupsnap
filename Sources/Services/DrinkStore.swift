import Foundation
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class DrinkStore: ObservableObject {
    static let shared = DrinkStore()

    @Published var entries: [DrinkEntry] = []
    @Published var selectedMonth: Date = Date()

    private let fm = FileManager.default
    private let baseDir: URL
    private let stickersDir: URL
    private let entriesURL: URL

    init(customDirectory: URL? = nil) {
        if let customDirectory {
            self.baseDir = customDirectory
        } else {
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.baseDir = docs.appendingPathComponent("CupSnapData", isDirectory: true)
        }
        self.stickersDir = baseDir.appendingPathComponent("Stickers", isDirectory: true)
        self.entriesURL = baseDir.appendingPathComponent("drinks_v1.json")

        try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: stickersDir, withIntermediateDirectories: true)

        load()
        if entries.isEmpty && !UserDefaults.standard.bool(forKey: "cupsnap_seeded_once_v1") {
            seedStarterShowcase()
            UserDefaults.standard.set(true, forKey: "cupsnap_seeded_once_v1")
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: entriesURL),
              let decoded = try? JSONDecoder.cupDecoder.decode([DrinkEntry].self, from: data) else {
            return
        }
        self.entries = decoded.sorted { $0.date > $1.date }
    }

    func save() {
        guard let data = try? JSONEncoder.cupEncoder.encode(entries) else { return }
        try? data.write(to: entriesURL, options: [.atomic])
    }

    func addEntry(_ entry: DrinkEntry, customStickerImage: UIImage? = nil) {
        var mutable = entry
        if let customStickerImage {
            let fileName = "\(mutable.id.uuidString).png"
            let url = stickersDir.appendingPathComponent(fileName)
            if let png = customStickerImage.pngData() {
                try? png.write(to: url, options: [.atomic])
                mutable.customStickerFileName = fileName
            }
        }
        entries.insert(mutable, at: 0)
        entries.sort { $0.date > $1.date }
        save()
        maybePromptGentleReview()
    }

    func updateEntry(_ entry: DrinkEntry, customStickerImage: UIImage? = nil) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        var mutable = entry
        if let customStickerImage {
            let fileName = "\(mutable.id.uuidString).png"
            let url = stickersDir.appendingPathComponent(fileName)
            if let png = customStickerImage.pngData() {
                try? png.write(to: url, options: [.atomic])
                mutable.customStickerFileName = fileName
            }
        }
        entries[idx] = mutable
        entries.sort { $0.date > $1.date }
        save()
    }

    func deleteEntry(_ entry: DrinkEntry) {
        if let fn = entry.customStickerFileName {
            try? fm.removeItem(at: stickersDir.appendingPathComponent(fn))
        }
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clearSampleEntries() {
        entries.removeAll { $0.isSampleData }
        save()
    }

    var hasSampleEntries: Bool {
        entries.contains { $0.isSampleData }
    }

    func loadCustomSticker(fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = stickersDir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func entries(inMonth monthDate: Date) -> [DrinkEntry] {
        let cal = Calendar.current
        let target = cal.dateComponents([.year, .month], from: monthDate)
        return entries.filter {
            let c = cal.dateComponents([.year, .month], from: $0.date)
            return c.year == target.year && c.month == target.month
        }.sorted { $0.date < $1.date }
    }

    func entries(onDay day: Date) -> [DrinkEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    func monthlyStats(for monthDate: Date) -> MonthlyDrinkStats {
        let list = entries(inMonth: monthDate)
        let count = list.count
        let spend = list.reduce(0.0) { $0 + $1.price }
        let caffeine = list.reduce(0) { $0 + $1.caffeineMg }
        let calories = list.reduce(0) { $0 + $1.caloriesKcal }

        var brandCounts: [String: Int] = [:]
        var catCounts: [DrinkCategory: Int] = [:]
        var sugarCounts: [SugarLevel: Int] = [:]
        for item in list {
            brandCounts[item.brand, default: 0] += 1
            catCounts[item.category, default: 0] += 1
            sugarCounts[item.sugar, default: 0] += 1
        }

        let topBrands = brandCounts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
        let topBrand = topBrands.first?.0 ?? "—"
        let favSugar = sugarCounts.sorted { $0.value > $1.value }.first?.key ?? .thirty

        return MonthlyDrinkStats(
            totalCups: count,
            totalSpend: spend,
            totalCaffeineMg: caffeine,
            totalCaloriesKcal: calories,
            topBrand: topBrand,
            topBrands: topBrands,
            categoryBreakdown: catCounts,
            favoriteSugar: favSugar
        )
    }

    func personalityTitle(for stats: MonthlyDrinkStats, isZh: Bool) -> (title: String, subtitle: String) {
        if stats.totalCups == 0 {
            return isZh
                ? ("清流养生派", "本月还没开喝，拍下你的第一杯贴纸吧")
                : ("Zen Sipper", "Ready for your very first cup sticker")
        }
        let coffeeCount = stats.categoryBreakdown[.coffee] ?? 0
        let milkTeaCount = stats.categoryBreakdown[.milkTea] ?? 0
        if Double(coffeeCount) / Double(max(1, stats.totalCups)) >= 0.5 {
            return isZh
                ? ("早C续命永动机", "血管里流淌着美式与生椰，靠咖啡因精准续航")
                : ("Caffeine Powered", "Running smoothly on espresso & iced oat lattes")
        }
        if stats.favoriteSugar == .full || stats.favoriteSugar == .seventy {
            return isZh
                ? ("全糖快乐星球原住民", "生活已经够苦了，这杯必须加满快乐糖分")
                : ("Sweet Tooth Royal", "Life's sweeter with extra boba and cheese foam")
        }
        if stats.favoriteSugar == .zero || stats.favoriteSugar == .thirty {
            return isZh
                ? ("控糖美学鉴茶官", "既要好喝又要轻负担，三分微甜拿捏精致生活")
                : ("Light-Sip Connoisseur", "Low sugar, high aesthetic — balanced every cup")
        }
        if milkTeaCount >= 4 {
            return isZh
                ? ("\(stats.topBrand) 荣誉股东", "本月狂贴 \(stats.totalCups) 杯，奶茶墙已经铺满幸福感")
                : ("\(stats.topBrand) VIP", "\(stats.totalCups) cups collected with joy this month")
        }
        return isZh
            ? ("城市饮品收集家", "把平凡日子里的小确幸，一杯杯贴成彩色日历")
            : ("Daily Cup Collector", "Turning everyday sips into tiny joyful stickers")
    }

    // 导出无损 JSON 备份文件（彻底解决竞品「换机/卸载丢数据」差评痛点）
    func exportBackupJSON() -> Data? {
        try? JSONEncoder.cupEncoder.encode(entries)
    }

    @discardableResult
    func importBackupJSON(_ data: Data) -> Int {
        guard let decoded = try? JSONDecoder.cupDecoder.decode([DrinkEntry].self, from: data) else {
            return 0
        }
        let existingIds = Set(entries.map { $0.id })
        let newItems = decoded.filter { !existingIds.contains($0.id) }
        entries.append(contentsOf: newItems)
        entries.sort { $0.date > $1.date }
        save()
        return newItems.count
    }

    func exportCSVString(isZh: Bool) -> String {
        let header = isZh
            ? "日期,品牌,饮品,品类,金额(元),糖度,冰度,咖啡因(mg),热量(kcal),评分,备注\n"
            : "Date,Brand,Drink,Category,Price,Sugar,Ice,Caffeine(mg),Calories(kcal),Rating,Note\n"
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        var rows = [header]
        for e in entries {
            let cleanNote = e.note.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
            let line = "\(df.string(from: e.date)),\(e.brand),\(e.drinkName),\(e.category.title(isZh)),\(String(format: "%.2f", e.price)),\(e.sugar.title(isZh)),\(e.ice.title(isZh)),\(e.caffeineMg),\(e.caloriesKcal),\(e.rating),\(cleanNote)\n"
            rows.append(line)
        }
        return rows.joined()
    }

    private func maybePromptGentleReview() {
        let realCount = entries.filter { !$0.isSampleData }.count
        let prompted = UserDefaults.standard.bool(forKey: "cupsnap_review_prompted_v1")
        if realCount == 3 && !prompted {
            UserDefaults.standard.set(true, forKey: "cupsnap_review_prompted_v1")
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        }
    }

    func seedStarterShowcase() {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let todayDay = cal.component(.day, from: now)

        func makeDate(day: Int, hour: Int) -> Date {
            let safeDay = max(1, min(day, max(todayDay, 18)))
            return cal.date(from: DateComponents(year: comps.year, month: comps.month, day: safeDay, hour: hour, minute: 20)) ?? now
        }

        let samples: [(Int, String, String, DrinkCategory, Double, SugarLevel, IceLevel, Int, PresetCupStyle, String, Double)] = [
            (1, "霸王茶姬", "伯牙绝弦", .milkTea, 20.0, .thirty, .lessIce, 5, .jasmineSilk, "茉莉花香太治愈了，轻乳完全不腻", -4.5),
            (3, "瑞幸咖啡", "生椰拿铁", .coffee, 9.9, .zero, .normalIce, 5, .luckinCoconut, "周一早八救命神器，9.9真香", 3.5),
            (5, "爷爷不泡茶", "荔枝冰酿", .milkTea, 17.0, .thirty, .noIce, 5, .grandpaLychee, "小众宝藏！荔枝米酿口感绝了", -3.0),
            (7, "喜茶", "多肉葡萄", .fruitTea, 19.0, .fifty, .lessIce, 4, .grapeOolong, "芝士奶盖配手剥葡萄果肉", 5.0),
            (9, "东方茉兰", "青瓷乌龙轻乳", .milkTea, 18.0, .thirty, .lessIce, 5, .orientPorcelain, "杯子好看得舍不得扔，拍照秒变贴纸", -5.0),
            (11, "Manner Coffee", "冰美式", .coffee, 15.0, .zero, .normalIce, 4, .icedAmericano, "自带杯减5元，清爽提神", 2.5),
            (13, "阿嬷手作", "打米麻薯牛乳", .milkTea, 29.0, .fifty, .warm, 5, .taroMochi, "排了半小时，底部热麻薯超满足", -2.5),
            (15, "古茗", "芝士莓莓", .fruitTea, 18.0, .thirty, .lessIce, 4, .strawberryCheese, "粉粉嫩嫩，周五快乐水", 4.0),
            (17, "星巴克", "焦糖玛奇朵", .coffee, 32.0, .fifty, .hot, 4, .warmLatte, "下雨天捧一杯热拿铁幸福感拉满", -4.0),
            (18, "柠季", "鸭屎香手打柠檬茶", .fruitTea, 16.0, .fifty, .normalIce, 5, .lemonPunch, "吃火锅解腻必备", 3.0),
            (20, "茶百道", "抹茶云顶奶绿", .matcha, 19.0, .thirty, .lessIce, 5, .matchaCloud, "宇治抹茶味很浓，微苦回甘", -3.5),
            (21, "一点点", "黑糖波波牛乳", .milkTea, 15.0, .seventy, .lessIce, 5, .caramelBoba, "经典永不过时，软糯黑糖珍珠", 4.5),
        ]

        var built: [DrinkEntry] = []
        for s in samples where s.0 <= max(todayDay, 21) {
            let entry = DrinkEntry(
                date: makeDate(day: s.0, hour: 14),
                brand: s.1,
                drinkName: s.2,
                category: s.3,
                price: s.4,
                sugar: s.5,
                ice: s.6,
                rating: s.7,
                caffeineMg: s.3.defaultCaffeineMg,
                caloriesKcal: Int(Double(s.3.defaultCaloriesKcal) * s.5.calorieMultiplier),
                note: s.9,
                presetCup: s.8,
                frameStyle: .dieCutWhite,
                customStickerFileName: nil,
                tiltDegrees: s.10,
                isSampleData: true
            )
            built.append(entry)
        }
        self.entries = built.sorted { $0.date > $1.date }
        save()
    }
}

struct MonthlyDrinkStats {
    let totalCups: Int
    let totalSpend: Double
    let totalCaffeineMg: Int
    let totalCaloriesKcal: Int
    let topBrand: String
    let topBrands: [(String, Int)]
    let categoryBreakdown: [DrinkCategory: Int]
    let favoriteSugar: SugarLevel
}

private extension JSONEncoder {
    static var cupEncoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }
}

private extension JSONDecoder {
    static var cupDecoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }
}
