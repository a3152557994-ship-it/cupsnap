import Foundation
import UIKit
import Vision

struct ParsedDrinkReceipt: Equatable {
    var brand: String
    var drinkName: String
    var category: DrinkCategory
    var price: Double
    var sugar: SugarLevel
    var ice: IceLevel
    var suggestedCup: PresetCupStyle
    var caffeineMg: Int
    var caloriesKcal: Int
    var rawText: String
}

struct ReceiptSamplePreset: Identifiable {
    let id: String
    let titleZh: String
    let titleEn: String
    let brandHint: String
    let rawReceiptText: String
    let cupStyle: PresetCupStyle
}

final class ReceiptOCREngine {
    static let shared = ReceiptOCREngine()

    struct BrandSpec {
        let canonical: String
        let aliases: [String]
        let defaultCategory: DrinkCategory
        let defaultCup: PresetCupStyle
    }

    // 涵盖国内头部、区域爆红及海外常见奶茶咖啡品牌（重点补全竞品差评缺失的小众品牌）
    let brandCatalog: [BrandSpec] = [
        BrandSpec(canonical: "爷爷不泡茶", aliases: ["爷爷不泡茶", "grandpa"], defaultCategory: .milkTea, defaultCup: .grandpaLychee),
        BrandSpec(canonical: "东方茉兰", aliases: ["东方茉兰"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "霸王茶姬", aliases: ["霸王茶姬", "chagee"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "瑞幸咖啡", aliases: ["瑞幸", "luckin"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "喜茶", aliases: ["喜茶", "heytea"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "茶颜悦色", aliases: ["茶颜悦色", "茶颜"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "阿嬷手作", aliases: ["阿嬷手作", "阿嬷"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "茉莉奶白", aliases: ["茉莉奶白"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "古茗", aliases: ["古茗", "goodme"], defaultCategory: .milkTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "茶百道", aliases: ["茶百道", "chapanda"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "蜜雪冰城", aliases: ["蜜雪冰城", "蜜雪", "mixue"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "沪上阿姨", aliases: ["沪上阿姨"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "奈雪的茶", aliases: ["奈雪", "nayuki"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "一点点", aliases: ["一点点", "1点点", "alittle"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "CoCo都可", aliases: ["coco", "都可"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "乐乐茶", aliases: ["乐乐茶", "leletea"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "星巴克", aliases: ["星巴克", "starbucks"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Manner Coffee", aliases: ["manner"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "M Stand", aliases: ["m stand", "mstand"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "库迪咖啡", aliases: ["库迪", "cotti"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "幸运咖", aliases: ["幸运咖"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "Grid Coffee", aliases: ["grid coffee", "grid"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Seesaw Coffee", aliases: ["seesaw"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "挪瓦咖啡", aliases: ["挪瓦", "nowwa"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "Peet's Coffee", aliases: ["peet", "皮爷"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Blue Bottle", aliases: ["blue bottle", "蓝瓶"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "% Arabica", aliases: ["arabica"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "去茶山", aliases: ["去茶山"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "茶话弄", aliases: ["茶话弄"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "放哈", aliases: ["放哈"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "柠季", aliases: ["柠季", "linlee", "林里"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "茶理宜世", aliases: ["茶理宜世"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "益禾堂", aliases: ["益禾堂"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "书亦烧仙草", aliases: ["书亦"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "甜啦啦", aliases: ["甜啦啦"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "七分甜", aliases: ["七分甜"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "裕莲茶楼", aliases: ["裕莲茶楼"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "煲珠公", aliases: ["煲珠公"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "淡马茶坊", aliases: ["淡马茶坊"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "代数学家", aliases: ["代数学家", "algebraist"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Tim Hortons", aliases: ["tims", "tim hortons", "天好"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Boba Guys", aliases: ["boba guys"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Gong Cha", aliases: ["gong cha", "贡茶"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Tiger Sugar", aliases: ["tiger sugar", "老虎堂"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
    ]

    let sampleReceipts: [ReceiptSamplePreset] = [
        ReceiptSamplePreset(
            id: "grandpa_lychee",
            titleZh: "爷爷不泡茶 · 荔枝冰酿",
            titleEn: "Grandpa Tea · Lychee",
            brandHint: "爷爷不泡茶",
            rawReceiptText: "爷爷不泡茶 (杭州湖滨店)\n取餐号 A208\n荔枝冰酿 (大杯)\n三分糖 / 去冰 / 脆波波\n实付金额 ¥17.00\n2026-11-21 14:22",
            cupStyle: .grandpaLychee
        ),
        ReceiptSamplePreset(
            id: "chagee_boya",
            titleZh: "霸王茶姬 · 伯牙绝弦",
            titleEn: "CHAGEE · Boya Jasmine",
            brandHint: "霸王茶姬",
            rawReceiptText: "霸王茶姬 CHAGEE\n取茶码 T066\n伯牙绝弦 (大杯)\n少甜 / 少冰\n合计实付 ￥20.00",
            cupStyle: .jasmineSilk
        ),
        ReceiptSamplePreset(
            id: "luckin_coco",
            titleZh: "瑞幸咖啡 · 生椰拿铁",
            titleEn: "Luckin · Coconut Latte",
            brandHint: "瑞幸咖啡",
            rawReceiptText: "瑞幸咖啡 luckin coffee\n生椰拿铁 (大杯)\n不另外加糖 / 冰\n实付 ¥9.90",
            cupStyle: .luckinCoconut
        )
    ]

    func recognizeImage(_ image: UIImage) async -> ParsedDrinkReceipt {
        let lines = await extractTextLines(from: image)
        let joined = lines.joined(separator: "\n")
        return parseText(joined)
    }

    private func extractTextLines(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["zh-Hans", "en-US"]
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    let texts = observations.compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: texts)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func parseText(_ rawText: String) -> ParsedDrinkReceipt {
        let normalized = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = normalized.lowercased()
        let lines = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 1. 匹配品牌
        var matchedBrand: BrandSpec?
        for spec in brandCatalog {
            if spec.aliases.contains(where: { lower.contains($0.lowercased()) }) {
                matchedBrand = spec
                break
            }
        }

        let brand = matchedBrand?.canonical ?? guessBrandFromLines(lines)
        var category = matchedBrand?.defaultCategory ?? inferCategory(lower)
        var cup = matchedBrand?.defaultCup ?? inferCupStyle(lower, category: category)

        // 2. 识别饮品名称
        let drinkName = extractDrinkName(lines: lines, brandAliases: matchedBrand?.aliases ?? [brand])
        if inferCategory(drinkName.lowercased()) != .milkTea || matchedBrand == nil {
            let inferred = inferCategory((drinkName + " " + lower).lowercased())
            if inferred != .milkTea || matchedBrand == nil {
                category = inferred
            }
        }
        cup = inferCupStyle((drinkName + " " + lower).lowercased(), category: category, fallback: cup)

        // 3. 识别实付价格
        let price = extractPrice(from: normalized) ?? (category == .coffee ? 15.0 : 18.0)

        // 4. 识别糖度
        let sugar = extractSugar(from: lower)

        // 5. 识别冰度
        let ice = extractIce(from: lower)

        // 6. 咖啡因与热量估算
        let caffeine = estimateCaffeine(text: lower, category: category)
        let calories = Int(Double(category.defaultCaloriesKcal) * sugar.calorieMultiplier)

        return ParsedDrinkReceipt(
            brand: brand,
            drinkName: drinkName,
            category: category,
            price: price,
            sugar: sugar,
            ice: ice,
            suggestedCup: cup,
            caffeineMg: caffeine,
            caloriesKcal: calories,
            rawText: normalized
        )
    }

    private func guessBrandFromLines(_ lines: [String]) -> String {
        for line in lines {
            if line.count >= 2 && line.count <= 14 && !line.contains("¥") && !line.contains("￥") && !line.contains("取餐") && !line.contains("订单") {
                return line.replacingOccurrences(of: "(", with: " ").components(separatedBy: " ").first ?? line
            }
        }
        return "自选茶饮"
    }

    private func extractDrinkName(lines: [String], brandAliases: [String]) -> String {
        let drinkKeywords = ["拿铁", "美式", "奶茶", "冰酿", "绝弦", "轻乳", "芝士", "波波", "芋泥", "麻薯", "抹茶", "葡萄", "柠檬", "杨枝甘露", "乌龙", "茉莉", "龙井", "可可", "摩卡", "卡布奇诺", "冷萃", "澳白", "latte", "americano", "matcha", "boba", "tea", "mocha", "brew"]
        let skipKeywords = ["取餐", "取茶", "订单", "实付", "合计", "小计", "电话", "地址", "时间", "欢迎", "美团", "饿了么", "支付", "发票", "优惠", "202"]

        for line in lines {
            let l = line.lowercased()
            if skipKeywords.contains(where: { l.contains($0) }) { continue }
            if drinkKeywords.contains(where: { l.contains($0) }) {
                return cleanDrinkTitle(line)
            }
        }

        for line in lines {
            let l = line.lowercased()
            if skipKeywords.contains(where: { l.contains($0) }) { continue }
            if brandAliases.contains(where: { !$0.isEmpty && l.contains($0.lowercased()) }) { continue }
            if l.contains("分糖") || l.contains("去冰") || l.contains("少冰") || l.contains("¥") || l.contains("￥") { continue }
            if line.count >= 2 && line.count <= 22 {
                return cleanDrinkTitle(line)
            }
        }
        return "今日续命特调"
    }

    private func cleanDrinkTitle(_ text: String) -> String {
        var s = text
        for pattern in ["\\(.*?\\)", "（.*?）", "[xX×]\\s*\\d+", "¥\\s*\\d+(\\.\\d+)?", "￥\\s*\\d+(\\.\\d+)?"] {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
            }
        }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? text : trimmed
    }

    private func extractPrice(from text: String) -> Double? {
        // 优先匹配带「实付/合计/¥/￥/$」的数字
        let patterns = [
            "(?:实付|合计|应付|总计)[^0-9]{0,6}(\\d{1,3}(?:\\.\\d{1,2})?)",
            "[¥￥\\$]\\s*(\\d{1,3}(?:\\.\\d{1,2})?)",
            "(\\d{1,3}(?:\\.\\d{1,2})?)\\s*元"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let ns = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
                if let last = matches.last, last.numberOfRanges > 1 {
                    let valStr = ns.substring(with: last.range(at: 1))
                    if let val = Double(valStr), val > 0.5, val < 500 {
                        return val
                    }
                }
            }
        }
        return nil
    }

    private func extractSugar(from lower: String) -> SugarLevel {
        if lower.contains("不另外加糖") || lower.contains("不额外加糖") || lower.contains("无糖") || lower.contains("0糖") || lower.contains("0%") || lower.contains("no sugar") {
            return .zero
        }
        if lower.contains("三分") || lower.contains("3分") || lower.contains("微糖") || lower.contains("微甜") || lower.contains("30%") {
            return .thirty
        }
        if lower.contains("五分") || lower.contains("5分") || lower.contains("半糖") || lower.contains("50%") || lower.contains("half") {
            return .fifty
        }
        if lower.contains("七分") || lower.contains("7分") || lower.contains("少糖") || lower.contains("少甜") || lower.contains("70%") {
            return .seventy
        }
        if lower.contains("全糖") || lower.contains("标准糖") || lower.contains("100%") {
            return .full
        }
        return .thirty
    }

    private func extractIce(from lower: String) -> IceLevel {
        if lower.contains("去冰") || lower.contains("no ice") { return .noIce }
        if lower.contains("少冰") || lower.contains("微冰") || lower.contains("less ice") { return .lessIce }
        if lower.contains("温热") || lower.contains("常温") || lower.contains("温饮") || lower.contains("warm") { return .warm }
        if lower.contains("热饮") || lower.contains("烫") || lower.contains("hot") || lower.contains("/ 热") || lower.contains("（热") || lower.contains("(热") { return .hot }
        return .normalIce
    }

    private func inferCategory(_ lower: String) -> DrinkCategory {
        if lower.contains("抹茶") || lower.contains("可可") || lower.contains("matcha") || lower.contains("cocoa") { return .matcha }
        if lower.contains("拿铁") || lower.contains("美式") || lower.contains("咖啡") || lower.contains("澳白") || lower.contains("冷萃") || lower.contains("摩卡") || lower.contains("coffee") || lower.contains("latte") || lower.contains("americano") { return .coffee }
        if lower.contains("柠檬") || lower.contains("葡萄") || lower.contains("草莓") || lower.contains("杨枝") || lower.contains("果茶") || lower.contains("芒果") || lower.contains("西柚") || lower.contains("lemon") || lower.contains("berry") { return .fruitTea }
        if lower.contains("气泡") || lower.contains("苏打") || lower.contains("sparkl") { return .sparkling }
        return .milkTea
    }

    private func inferCupStyle(_ lower: String, category: DrinkCategory, fallback: PresetCupStyle? = nil) -> PresetCupStyle {
        if lower.contains("抹茶") || lower.contains("matcha") { return .matchaCloud }
        if lower.contains("生椰") || lower.contains("椰") || lower.contains("coconut") { return .luckinCoconut }
        if lower.contains("美式") || lower.contains("冷萃") || lower.contains("americano") { return .icedAmericano }
        if lower.contains("热") && category == .coffee { return .warmLatte }
        if lower.contains("草莓") || lower.contains("莓") || lower.contains("berry") { return .strawberryCheese }
        if lower.contains("荔枝") || lower.contains("爷爷不泡茶") { return .grandpaLychee }
        if lower.contains("葡萄") || lower.contains("grape") { return .grapeOolong }
        if lower.contains("柠檬") || lower.contains("lemon") { return .lemonPunch }
        if lower.contains("芋泥") || lower.contains("麻薯") || lower.contains("taro") { return .taroMochi }
        if lower.contains("黑糖") || lower.contains("波波") || lower.contains("珍珠") || lower.contains("boba") { return .caramelBoba }
        if lower.contains("伯牙") || lower.contains("茉莉") || lower.contains("霸王") { return .jasmineSilk }
        if lower.contains("东方茉兰") || lower.contains("乌龙") { return .orientPorcelain }
        if let fallback { return fallback }
        switch category {
        case .coffee: return .luckinCoconut
        case .matcha: return .matchaCloud
        case .fruitTea: return .strawberryCheese
        case .sparkling: return .lemonPunch
        case .milkTea: return .caramelBoba
        }
    }

    private func estimateCaffeine(text: String, category: DrinkCategory) -> Int {
        if text.contains("无咖啡因") || text.contains("decaf") { return 0 }
        if text.contains("双份") || text.contains("美式") || text.contains("冷萃") || text.contains("americano") { return 185 }
        if text.contains("伯牙") || text.contains("轻乳") || text.contains("乌龙") { return 115 }
        return category.defaultCaffeineMg
    }
}
