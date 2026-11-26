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

    // 涵盖全国连锁、区域热门及港台/海外 118 家主流奶茶、果茶、咖啡品牌
    let brandCatalog: [BrandSpec] = [
        // 一线全国现制茶饮与新式国风鲜乳茶
        BrandSpec(canonical: "爷爷不泡茶", aliases: ["爷爷不泡茶", "grandpa tea"], defaultCategory: .milkTea, defaultCup: .grandpaLychee),
        BrandSpec(canonical: "东方茉兰", aliases: ["东方茉兰"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "霸王茶姬", aliases: ["霸王茶姬", "chagee"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "喜茶", aliases: ["喜茶", "heytea"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "茶颜悦色", aliases: ["茶颜悦色", "茶颜"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "阿嬷手作", aliases: ["阿嬷手作", "阿嬷"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "茉莉奶白", aliases: ["茉莉奶白", "molly tea"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "古茗", aliases: ["古茗", "goodme"], defaultCategory: .milkTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "茶百道", aliases: ["茶百道", "chapanda"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "蜜雪冰城", aliases: ["蜜雪冰城", "蜜雪", "mixue"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "沪上阿姨", aliases: ["沪上阿姨", "阿姨鲜果茶"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "奈雪的茶", aliases: ["奈雪的茶", "奈雪", "nayuki"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "一点点", aliases: ["一点点", "1点点", "一點點", "alittle"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "CoCo都可", aliases: ["coco都可", "coco", "都可"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "乐乐茶", aliases: ["乐乐茶", "leletea"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "书亦烧仙草", aliases: ["书亦烧仙草", "书亦"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "益禾堂", aliases: ["益禾堂"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "甜啦啦", aliases: ["甜啦啦"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "七分甜", aliases: ["七分甜", "7分甜"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "煲珠公", aliases: ["煲珠公"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "裕莲茶楼", aliases: ["裕莲茶楼", "裕蓮茶樓"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "去茶山", aliases: ["去茶山"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "茶话弄", aliases: ["茶话弄"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "茶理宜世", aliases: ["茶理宜世", "charlie's tea"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "放哈", aliases: ["放哈"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "淡马茶坊", aliases: ["淡马茶坊"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "兰熊鲜奶", aliases: ["兰熊鲜奶", "兰熊"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "茉酸奶", aliases: ["茉酸奶", "more yogurt"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "一只酸奶牛", aliases: ["一只酸奶牛"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "卡旺卡", aliases: ["卡旺卡"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "眷茶", aliases: ["眷茶"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "椿风", aliases: ["椿风", "椿风养身茶饮"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "荷田水铺", aliases: ["荷田水铺"], defaultCategory: .fruitTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "伏小桃", aliases: ["伏小桃", "伏见桃山"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "桂桂茶", aliases: ["桂桂茶"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "百分茶", aliases: ["百分茶"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "阿水大杯茶", aliases: ["阿水大杯茶"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "冰雪时光", aliases: ["冰雪时光"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "吾饮良品", aliases: ["吾饮良品"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "悸动烧仙草", aliases: ["悸动烧仙草", "悸动"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "快乐柠檬", aliases: ["快乐柠檬", "happy lemon"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "大卡司", aliases: ["大卡司", "dakasi"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "兵立王", aliases: ["兵立王"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "茶主张", aliases: ["茶主张"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "新时沏", aliases: ["新时沏"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "琉璃净", aliases: ["琉璃净"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "蜜菓", aliases: ["蜜菓"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "700CC", aliases: ["700cc"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "周四晚", aliases: ["周四晚"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "山住茶", aliases: ["山住茶"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "唐沫茶兮", aliases: ["唐沫茶兮"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "壶见", aliases: ["壶见"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "煮叶", aliases: ["煮叶", "teasure"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "tea'stone", aliases: ["tea'stone", "teastone"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "三品王茶渊", aliases: ["茶渊"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),

        // 柠檬茶、鲜果茶与椰子特调连锁
        BrandSpec(canonical: "柠季", aliases: ["柠季"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "LINLEE林里", aliases: ["linlee", "林里", "鄰里"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "丘大叔柠檬茶", aliases: ["丘大叔"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "挞柠", aliases: ["挞柠", "tanning"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "茶救星球", aliases: ["茶救星球"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "泰柯茶园", aliases: ["泰柯茶园"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "王柠", aliases: ["王柠"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "啊一柠檬茶", aliases: ["啊一柠檬茶"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "果呀呀", aliases: ["果呀呀"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "野萃山", aliases: ["野萃山"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "鲜疯果局", aliases: ["鲜疯果局"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "茶大椰", aliases: ["茶大椰"], defaultCategory: .milkTea, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "蔻蔻椰", aliases: ["蔻蔻椰"], defaultCategory: .milkTea, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "椰不二", aliases: ["椰不二"], defaultCategory: .milkTea, defaultCup: .luckinCoconut),

        // 全国及精品现磨咖啡连锁
        BrandSpec(canonical: "瑞幸咖啡", aliases: ["瑞幸咖啡", "瑞幸", "luckin"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "星巴克", aliases: ["星巴克", "starbucks"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "库迪咖啡", aliases: ["库迪咖啡", "库迪", "cotti"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "Manner Coffee", aliases: ["manner coffee", "manner"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "M Stand", aliases: ["m stand", "mstand"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "幸运咖", aliases: ["幸运咖", "lucky cup"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "挪瓦咖啡", aliases: ["挪瓦咖啡", "挪瓦", "nowwa"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "Tim Hortons", aliases: ["tim hortons", "tims", "天好咖啡"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Peet's Coffee", aliases: ["peet's", "peets", "皮爷咖啡", "皮爷"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Blue Bottle", aliases: ["blue bottle", "蓝瓶咖啡", "藍瓶咖啡"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "% Arabica", aliases: ["% arabica", "arabica"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Grid Coffee", aliases: ["grid coffee"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "Seesaw Coffee", aliases: ["seesaw"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "代数学家", aliases: ["代数学家", "algebraist"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "比星咖啡", aliases: ["比星咖啡", "bixing"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "四叶咖", aliases: ["四叶咖", "clover coffee"], defaultCategory: .coffee, defaultCup: .luckinCoconut),
        BrandSpec(canonical: "小咖咖啡", aliases: ["小咖咖啡"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "津久咖啡", aliases: ["津久咖啡"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Lavazza拉瓦萨", aliases: ["lavazza", "拉瓦萨"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "Costa Coffee", aliases: ["costa coffee", "costa", "咖世家"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "太平洋咖啡", aliases: ["太平洋咖啡", "pacific coffee"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "麦咖啡", aliases: ["麦咖啡", "mccafe", "mccafé"], defaultCategory: .coffee, defaultCup: .warmLatte),
        BrandSpec(canonical: "肯悦咖啡", aliases: ["肯悦咖啡", "kcoffee"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "湃客咖啡", aliases: ["湃客咖啡", "let's cafe", "let's café"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "三顿半", aliases: ["三顿半", "saturnbird"], defaultCategory: .coffee, defaultCup: .icedAmericano),
        BrandSpec(canonical: "隅田川咖啡", aliases: ["隅田川", "tasogare"], defaultCategory: .coffee, defaultCup: .icedAmericano),

        // 港台及海外知名手摇饮品牌
        BrandSpec(canonical: "50岚 / KOI Thé", aliases: ["50岚", "50嵐", "koi thé", "koi the"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "吃茶三千", aliases: ["吃茶三千", "chicha san chen"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "春水堂", aliases: ["春水堂", "chun shui tang"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "天仁茗茶", aliases: ["天仁茗茶", "天仁喫茶趣", "喫茶趣", "tenren"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "迷客夏", aliases: ["迷客夏", "milksha"], defaultCategory: .milkTea, defaultCup: .taroMochi),
        BrandSpec(canonical: "清心福全", aliases: ["清心福全"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "麻古茶坊", aliases: ["麻古茶坊", "麻古", "macu tea"], defaultCategory: .fruitTea, defaultCup: .grapeOolong),
        BrandSpec(canonical: "得正", aliases: ["得正", "dejeng"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "一沐日", aliases: ["一沐日"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "八曜和茶", aliases: ["八曜和茶", "八曜"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "五桐号", aliases: ["五桐号", "五桐號", "wootea"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "龟记茗品", aliases: ["龟记", "龜記", "guiji"], defaultCategory: .fruitTea, defaultCup: .lemonPunch),
        BrandSpec(canonical: "可不可熟成红茶", aliases: ["可不可熟成红茶", "可不可熟成紅茶", "可不可", "kebuke"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "鹤茶楼", aliases: ["鹤茶楼", "鶴茶樓"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "万波岛屿红茶", aliases: ["万波", "萬波", "wanpo"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "大苑子", aliases: ["大苑子", "dayungs"], defaultCategory: .fruitTea, defaultCup: .strawberryCheese),
        BrandSpec(canonical: "珍煮丹", aliases: ["珍煮丹", "truedan"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "再睡5分钟", aliases: ["再睡5分钟", "再睡5分鐘", "nap tea"], defaultCategory: .milkTea, defaultCup: .jasmineSilk),
        BrandSpec(canonical: "兰芳园", aliases: ["兰芳园", "蘭芳園"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "茶汤会", aliases: ["茶汤会", "茶湯會", "tp tea"], defaultCategory: .milkTea, defaultCup: .orientPorcelain),
        BrandSpec(canonical: "COMEBUY", aliases: ["comebuy"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "日出茶太", aliases: ["日出茶太", "chatime"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "鹿角巷", aliases: ["鹿角巷", "the alley"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "歇脚亭", aliases: ["歇脚亭", "歇腳亭", "sharetea"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "幸福堂", aliases: ["幸福堂", "xing fu tang"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Gong Cha", aliases: ["gong cha", "贡茶", "貢茶"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Tiger Sugar", aliases: ["tiger sugar", "老虎堂"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Boba Guys", aliases: ["boba guys"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
        BrandSpec(canonical: "Kung Fu Tea", aliases: ["kung fu tea", "功夫茶"], defaultCategory: .milkTea, defaultCup: .caramelBoba),
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
                request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
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
        let simplifiedForMatch = (normalized.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? normalized)
        let lower = simplifiedForMatch.lowercased()
        let lines = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 1. 匹配品牌（同时匹配 canonical 与 aliases，按最长名称优先，防止短词误撞）
        var matchedBrand: BrandSpec?
        var bestAliasLength = 0
        for spec in brandCatalog {
            let candidates = [spec.canonical] + spec.aliases
            for rawCandidate in candidates {
                let cOrig = rawCandidate.lowercased()
                let cSimp = (rawCandidate.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? rawCandidate).lowercased()
                if !cSimp.isEmpty && (lower.contains(cSimp) || normalized.lowercased().contains(cOrig)) {
                    let matchLen = max(cSimp.count, cOrig.count)
                    if matchLen > bestAliasLength {
                        bestAliasLength = matchLen
                        matchedBrand = spec
                    }
                }
            }
        }

        let brand = matchedBrand?.canonical ?? guessBrandFromLines(lines)
        var category = matchedBrand?.defaultCategory ?? inferCategory(lower)
        var cup = matchedBrand?.defaultCup ?? inferCupStyle(lower, category: category)

        // 2. 识别饮品名称（显式跳过品牌门店抬头、备注、Wi-Fi、密码、余额、找零等非饮品行）
        let brandTokens: [String] = {
            guard let matchedBrand else { return [brand] }
            return [matchedBrand.canonical] + matchedBrand.aliases
        }()
        let drinkName = extractDrinkName(lines: lines, brandAliases: brandTokens)
        if inferCategory(drinkName.lowercased()) != .milkTea || matchedBrand == nil {
            let inferred = inferCategory((drinkName + " " + lower).lowercased())
            if inferred != .milkTea || matchedBrand == nil {
                category = inferred
            }
        }
        cup = inferCupStyle((drinkName + " " + lower).lowercased(), category: category, fallback: cup)

        // 3. 识别实付价格（优先实付/应付/合计/总计/应收，排除储值余额/找零/满减行）
        let price = extractPrice(from: simplifiedForMatch) ?? (category == .coffee ? 15.0 : 18.0)

        // 4. 识别糖度（小票未标注糖度时设为 .unspecified "未标注"，不强塞三分糖）
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
            let l = line.lowercased()
            if isNoiseOrMetadataLine(l) { continue }
            if line.count >= 2 && line.count <= 14 && !line.contains("¥") && !line.contains("￥") && !line.contains("$") {
                return line.replacingOccurrences(of: "(", with: " ").components(separatedBy: " ").first ?? line
            }
        }
        return "自选茶饮"
    }

    private func isNoiseOrMetadataLine(_ lowerLine: String) -> Bool {
        let skipKeywords = [
            "取餐", "取茶", "取单", "叫号", "流水", "订单", "单号", "账单",
            "实付", "应付", "应收", "实收", "合计", "总计", "小计",
            "余额", "储值", "卡内", "找零", "优惠", "立减", "满减", "折扣", "抵扣", "充值", "赠金", "积分", "红包", "优惠券",
            "备注", "留言", "顾客要求", "不要吸管", "放前台", "放门口", "打包", "纸袋", "保温袋", "配送费",
            "wifi", "wi-fi", "wlan", "密码", "password", "pwd",
            "电话", "热线", "客服", "地址", "门店", "店员", "收银", "桌号", "人数",
            "时间", "日期", "欢迎", "光临", "谢谢", "温馨提示", "赏味", "饮用建议",
            "美团", "饿了么", "京东秒送", "抖音团购", "微信支付", "支付宝", "支付成功", "发票", "扫码", "小程序"
        ]
        if skipKeywords.contains(where: { lowerLine.contains($0) }) {
            return true
        }
        // Pure date/time/order-number/phone lines (no Chinese/Latin letters or starts with 202x-)
        if lowerLine.range(of: "^20\\d{2}[-/.年]", options: .regularExpression) != nil {
            return true
        }
        if lowerLine.range(of: "^[0-9a-z#\\-:/\\s.]+$", options: .regularExpression) != nil {
            let hasDrinkWord = ["latte", "americano", "matcha", "boba", "tea", "mocha", "brew", "coffee", "cocoa", "milk"].contains {
                lowerLine.contains($0)
            }
            if !hasDrinkWord { return true }
        }
        return false
    }

    private func isPureSpecLine(_ lowerLine: String) -> Bool {
        let specWords = ["分糖", "无糖", "0糖", "微糖", "半糖", "少糖", "少甜", "全糖", "标准糖", "不另外加糖", "不额外加糖", "去冰", "少冰", "微冰", "正常冰", "常温", "温热", "热饮"]
        if specWords.contains(where: { lowerLine.contains($0) }) {
            // Only treat as pure spec line if it doesn't also carry a known drink noun
            return !containsDrinkKeyword(lowerLine)
        }
        return false
    }

    private func containsDrinkKeyword(_ lowerLine: String) -> Bool {
        let drinkKeywords = [
            "拿铁", "美式", "奶茶", "冰酿", "绝弦", "轻乳", "牛乳", "鲜奶", "厚乳", "燕麦奶", "水牛乳", "酸奶", "酪酪", "生酪",
            "芝士", "波波", "珍珠", "芋泥", "芋圆", "麻薯", "烧仙草", "双皮奶", "龟苓膏", "布丁", "奶冻",
            "抹茶", "可可", "阿华田", "摩卡", "卡布奇诺", "冷萃", "澳白", "馥芮白", "玛奇朵", "浓缩", "手冲", "鸳鸯",
            "葡萄", "柠檬", "柠茶", "冻柠茶", "杨枝甘露", "甘露", "草莓", "莓莓", "芒芒", "芒果", "西柚", "芭乐", "百香果", "蜜桃", "白桃", "青提", "桑葚", "车厘子", "荔枝", "橙c", "柑橘", "雪梨", "椰青", "生椰",
            "乌龙", "茉莉", "龙井", "红茶", "绿茶", "普洱", "单丛", "鸭屎香", "铁观音", "大红袍", "茗茶", "春山", "青瓷", "桂花", "桂馥", "兰香", "春芽", "冷露", "木兰", "浮云", "栀子", "白兰", "米酿", "酒酿", "气泡", "苏打", "冰沙", "雪顶", "果茶", "冰茶",
            "latte", "americano", "espresso", "cappuccino", "flat white", "macchiato", "matcha", "boba", "milk tea", "fruit tea", "lemon tea", "oolong", "jasmine", "mocha", "cold brew", "smoothie", "frappe"
        ]
        return drinkKeywords.contains(where: { lowerLine.contains($0) })
    }

    private func normalizedBrandTokens(_ brandAliases: [String]) -> [String] {
        var set = Set<String>()
        for alias in brandAliases {
            let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            set.insert(trimmed.lowercased())
            if let simp = trimmed.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) {
                set.insert(simp.lowercased())
            }
        }
        return set.sorted { $0.count > $1.count }
    }

    private func isBrandOrStoreHeaderLine(_ rawLine: String, simplifiedLower: String, sortedBrandTokens: [String]) -> Bool {
        let cleaned = cleanDrinkTitle(rawLine)
        let cleanedSimp = (cleaned.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? cleaned).lowercased()
        guard sortedBrandTokens.contains(where: { cleanedSimp.contains($0) || simplifiedLower.contains($0) }) else {
            return false
        }
        var remainder = cleanedSimp
        for token in sortedBrandTokens {
            remainder = remainder.replacingOccurrences(of: token, with: "")
        }
        remainder = remainder.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-·•/()（）[]【】")))
        if remainder.isEmpty {
            return true
        }
        // Store branch suffix like "台北信义店", "静安寺店", "旗舰店"
        if remainder.hasSuffix("店") && remainder.count <= 12 && !containsDrinkKeyword(remainder) {
            return true
        }
        return false
    }

    private func extractDrinkName(lines: [String], brandAliases: [String]) -> String {
        let sortedTokens = normalizedBrandTokens(brandAliases)

        // Pass 1: Lines containing explicit drink keywords and not brand header / noise / metadata
        for line in lines {
            let simplified = (line.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? line).lowercased()
            if isNoiseOrMetadataLine(simplified) { continue }
            if isBrandOrStoreHeaderLine(line, simplifiedLower: simplified, sortedBrandTokens: sortedTokens) { continue }

            if containsDrinkKeyword(simplified) {
                let cleaned = cleanDrinkTitle(line)
                if cleaned.count >= 2 {
                    return cleaned
                }
            }
        }

        // Pass 2: Clean short candidate product line (supports inline unit prices like "桂馥兰香 (大杯) ¥20.00", while rejecting pure price/spec/noise lines)
        for line in lines {
            let simplified = (line.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? line).lowercased()
            if isNoiseOrMetadataLine(simplified) { continue }
            if isPureSpecLine(simplified) { continue }
            if isBrandOrStoreHeaderLine(line, simplifiedLower: simplified, sortedBrandTokens: sortedTokens) { continue }

            let cleaned = cleanDrinkTitle(line)
            let cleanedLower = cleaned.lowercased()
            if cleaned.count >= 2 && cleaned.count <= 20 {
                // Ensure cleaned product name is not just digits/punctuation
                if cleanedLower.range(of: "[\\u4e00-\\u9fa5a-z]{2,}", options: .regularExpression) != nil {
                    return cleaned
                }
            }
        }
        return "今日特调饮品"
    }

    private func cleanDrinkTitle(_ text: String) -> String {
        var s = text
        let stripPatterns = [
            "\\(.*?\\)",
            "（.*?）",
            "\\[.*?\\]",
            "【.*?】",
            "[xX×*]\\s*\\d+",
            "(?:NT\\$|HK\\$|[¥￥\\$])\\s*\\d+(?:\\.\\d+)?",
            "\\d+(?:\\.\\d+)?\\s*元$"
        ]
        for pattern in stripPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
            }
        }
        return s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-·•/")))
    }

    func extractPrice(from text: String) -> Double? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let excludedKeywords = [
            "余额", "储值", "卡内", "找零", "优惠", "立减", "满减", "减免", "折扣", "抵扣",
            "已省", "省了", "充值", "赠金", "本金", "积分", "红包", "券", "配送费", "打包费",
            "balance", "change", "discount", "saved", "top-up", "topup", "coupon"
        ]

        let tier1PaidKeywords = ["实付金额", "应付金额", "应收金额", "合计实付", "订单实付", "支付金额", "实付", "应付", "应收", "实收", "amount due", "paid"]
        let tier2TotalKeywords = ["总计", "合计", "小计", "total"]

        // Helper to extract a positive price following a specific keyword on the same line, or from the next line
        func matchKeywordTier(_ keywords: [String]) -> Double? {
            for (idx, line) in lines.enumerated() {
                let lower = line.lowercased()
                // Ignore lines like "优惠合计" / "共优惠" / "储值余额"
                if lower.contains("优惠合计") || lower.contains("合计优惠") || lower.contains("共优惠") || lower.contains("储值") || lower.contains("余额") || lower.contains("找零") || lower.contains("充值") {
                    continue
                }
                for kw in keywords {
                    guard let kwRange = lower.range(of: kw) else { continue }
                    let tail = String(lower[kwRange.upperBound...])
                    if let sameLineVal = extractFirstPositiveAmount(from: tail) {
                        return sameLineVal
                    }
                    // Check immediately following line if current line was just a label like "实付金额" or "应收："
                    if idx + 1 < lines.count {
                        let nextLower = lines[idx + 1].lowercased()
                        if !excludedKeywords.contains(where: { nextLower.contains($0) }),
                           let nextLineVal = extractFirstPositiveAmount(from: nextLower) {
                            return nextLineVal
                        }
                    }
                }
            }
            return nil
        }

        if let paid = matchKeywordTier(tier1PaidKeywords) {
            return paid
        }
        if let total = matchKeywordTier(tier2TotalKeywords) {
            return total
        }

        // Fallback: scan non-excluded lines for explicit currency amounts (¥ / ￥ / $ / NT$ / HK$ / 元)
        let currencyPatterns = [
            "(?<![-\\d])(?:nt\\$|hk\\$|[¥￥\\$])\\s*(\\d{1,3}(?:\\.\\d{1,2})?)",
            "(?<![-\\d])(\\d{1,3}(?:\\.\\d{1,2})?)\\s*元"
        ]
        for line in lines {
            let lower = line.lowercased()
            if excludedKeywords.contains(where: { lower.contains($0) }) { continue }
            for pat in currencyPatterns {
                if let regex = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) {
                    let ns = lower as NSString
                    let matches = regex.matches(in: lower, range: NSRange(location: 0, length: ns.length))
                    for m in matches where m.numberOfRanges > 1 {
                        if let val = Double(ns.substring(with: m.range(at: 1))), val >= 1.0, val <= 300.0 {
                            return val
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractFirstPositiveAmount(from text: String) -> Double? {
        // Skip negative discount numbers like "-¥3.00" or "- 5.00"
        let pattern = "(?<![-−–\\d])(?:nt\\$|hk\\$|[¥￥\\$])?\\s*(\\d{1,3}(?:\\.\\d{1,2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for m in matches where m.numberOfRanges > 1 {
            // Check character right before match is not a minus sign
            if m.range.location > 0 {
                let prevChar = ns.substring(with: NSRange(location: m.range.location - 1, length: 1))
                if prevChar == "-" || prevChar == "−" || prevChar == "–" { continue }
            }
            let rawNum = ns.substring(with: m.range(at: 1))
            if let val = Double(rawNum), val >= 0.5, val <= 350.0 {
                return val
            }
        }
        return nil
    }

    private func extractSugar(from lower: String) -> SugarLevel {
        if lower.contains("不另外加糖") || lower.contains("不额外加糖") || lower.contains("无糖") || lower.contains("0糖") || lower.contains("零糖") || lower.contains("走甜") || lower.contains("去糖") || lower.contains("0%糖") || lower.contains("no sugar") || lower.contains("unsweetened") || lower.contains("sugar free") {
            return .zero
        }
        if lower.contains("三分") || lower.contains("3分") || lower.contains("一分") || lower.contains("1分") || lower.contains("微糖") || lower.contains("微甜") || lower.contains("30%") {
            return .thirty
        }
        if lower.contains("五分") || lower.contains("5分") || lower.contains("半糖") || lower.contains("半甜") || lower.contains("50%") || lower.contains("half sugar") {
            return .fifty
        }
        if lower.contains("七分") || lower.contains("7分") || lower.contains("八分") || lower.contains("少糖") || lower.contains("少甜") || lower.contains("70%") || lower.contains("less sweet") {
            return .seventy
        }
        if lower.contains("全糖") || lower.contains("标准糖") || lower.contains("正常糖") || lower.contains("正常甜") || lower.contains("多糖") || lower.contains("100%糖") || lower.contains("regular sugar") || lower.contains("full sugar") {
            return .full
        }
        return .unspecified
    }

    private func extractIce(from lower: String) -> IceLevel {
        if lower.contains("去冰") || lower.contains("走冰") || lower.contains("0冰") || lower.contains("no ice") { return .noIce }
        if lower.contains("少冰") || lower.contains("微冰") || lower.contains("less ice") { return .lessIce }
        if lower.contains("温热") || lower.contains("常温") || lower.contains("温饮") || lower.contains("warm") { return .warm }
        if lower.contains("热饮") || lower.contains("烫") || lower.contains("hot") || lower.contains("/ 热") || lower.contains("（热") || lower.contains("(热") { return .hot }
        return .normalIce
    }

    private func inferCategory(_ lower: String) -> DrinkCategory {
        if lower.contains("抹茶") || lower.contains("可可") || lower.contains("matcha") || lower.contains("cocoa") { return .matcha }
        if lower.contains("拿铁") || lower.contains("美式") || lower.contains("咖啡") || lower.contains("澳白") || lower.contains("馥芮白") || lower.contains("冷萃") || lower.contains("摩卡") || lower.contains("卡布奇诺") || lower.contains("coffee") || lower.contains("latte") || lower.contains("americano") { return .coffee }
        if lower.contains("柠檬") || lower.contains("柠茶") || lower.contains("葡萄") || lower.contains("草莓") || lower.contains("杨枝") || lower.contains("果茶") || lower.contains("芒果") || lower.contains("西柚") || lower.contains("芭乐") || lower.contains("百香果") || lower.contains("lemon") || lower.contains("berry") { return .fruitTea }
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
        if lower.contains("柠檬") || lower.contains("柠茶") || lower.contains("lemon") { return .lemonPunch }
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
