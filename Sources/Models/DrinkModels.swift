import Foundation
import SwiftUI

enum DrinkCategory: String, Codable, CaseIterable, Identifiable {
    case milkTea = "milk_tea"
    case coffee = "coffee"
    case fruitTea = "fruit_tea"
    case matcha = "matcha"
    case sparkling = "sparkling"

    var id: String { rawValue }

    func title(_ isZh: Bool) -> String {
        switch self {
        case .milkTea: return isZh ? "奶茶鲜乳" : "Milk Tea"
        case .coffee: return isZh ? "现磨咖啡" : "Coffee"
        case .fruitTea: return isZh ? "鲜果茶饮" : "Fruit Tea"
        case .matcha: return isZh ? "抹茶可可" : "Matcha"
        case .sparkling: return isZh ? "特调气泡" : "Sparkler"
        }
    }

    var badgeColorHex: String {
        switch self {
        case .milkTea: return "D98E54"
        case .coffee: return "6E442A"
        case .fruitTea: return "E56E80"
        case .matcha: return "5C8D67"
        case .sparkling: return "5A8DB8"
        }
    }

    var defaultCaffeineMg: Int {
        switch self {
        case .milkTea: return 95
        case .coffee: return 145
        case .fruitTea: return 45
        case .matcha: return 78
        case .sparkling: return 20
        }
    }

    var defaultCaloriesKcal: Int {
        switch self {
        case .milkTea: return 310
        case .coffee: return 135
        case .fruitTea: return 210
        case .matcha: return 260
        case .sparkling: return 120
        }
    }
}

enum SugarLevel: String, Codable, CaseIterable, Identifiable {
    case unspecified = "unspecified"
    case zero = "zero"
    case thirty = "thirty"
    case fifty = "fifty"
    case seventy = "seventy"
    case full = "full"

    var id: String { rawValue }

    func title(_ isZh: Bool) -> String {
        switch self {
        case .unspecified: return isZh ? "未标注" : "Unlisted"
        case .zero: return isZh ? "不额外加糖" : "0% Sugar"
        case .thirty: return isZh ? "三分微甜" : "30% Less"
        case .fifty: return isZh ? "五分半糖" : "50% Half"
        case .seventy: return isZh ? "七分少甜" : "70% Mild"
        case .full: return isZh ? "全糖快乐" : "100% Full"
        }
    }

    var shortLabel: String {
        switch self {
        case .unspecified: return "未标注"
        case .zero: return "0%"
        case .thirty: return "30%"
        case .fifty: return "50%"
        case .seventy: return "70%"
        case .full: return "100%"
        }
    }

    var calorieMultiplier: Double {
        switch self {
        case .unspecified: return 1.0
        case .zero: return 0.58
        case .thirty: return 0.78
        case .fifty: return 0.92
        case .seventy: return 1.05
        case .full: return 1.25
        }
    }
}

enum IceLevel: String, Codable, CaseIterable, Identifiable {
    case normalIce = "normal_ice"
    case lessIce = "less_ice"
    case noIce = "no_ice"
    case warm = "warm"
    case hot = "hot"

    var id: String { rawValue }

    func title(_ isZh: Bool) -> String {
        switch self {
        case .normalIce: return isZh ? "正常冰" : "Regular Ice"
        case .lessIce: return isZh ? "少冰" : "Less Ice"
        case .noIce: return isZh ? "去冰" : "No Ice"
        case .warm: return isZh ? "温饮" : "Warm"
        case .hot: return isZh ? "热饮" : "Hot"
        }
    }
}

enum StickerFrameStyle: String, Codable, CaseIterable, Identifiable {
    case dieCutWhite = "die_cut_white"
    case polaroid = "polaroid"
    case stamp = "stamp"
    case washiTape = "washi_tape"

    var id: String { rawValue }

    func title(_ isZh: Bool) -> String {
        switch self {
        case .dieCutWhite: return isZh ? "经典白边" : "Die-Cut"
        case .polaroid: return isZh ? "拍立得" : "Polaroid"
        case .stamp: return isZh ? "复古邮票" : "Stamp"
        case .washiTape: return isZh ? "和纸胶带" : "Washi"
        }
    }
}

enum PresetCupStyle: String, Codable, CaseIterable, Identifiable {
    case caramelBoba = "caramel_boba"
    case jasmineSilk = "jasmine_silk"
    case luckinCoconut = "luckin_coconut"
    case matchaCloud = "matcha_cloud"
    case strawberryCheese = "strawberry_cheese"
    case grandpaLychee = "grandpa_lychee"
    case orientPorcelain = "orient_porcelain"
    case taroMochi = "taro_mochi"
    case lemonPunch = "lemon_punch"
    case icedAmericano = "iced_americano"
    case warmLatte = "warm_latte"
    case grapeOolong = "grape_oolong"

    var id: String { rawValue }

    func label(_ isZh: Bool) -> String {
        switch self {
        case .caramelBoba: return isZh ? "黑糖波波" : "Brown Boba"
        case .jasmineSilk: return isZh ? "国风轻乳" : "Jasmine Tea"
        case .luckinCoconut: return isZh ? "生椰拿铁" : "Coco Latte"
        case .matchaCloud: return isZh ? "抹茶云顶" : "Matcha Cloud"
        case .strawberryCheese: return isZh ? "莓果芝士" : "Berry Foam"
        case .grandpaLychee: return isZh ? "荔枝冰酿" : "Lychee Pink"
        case .orientPorcelain: return isZh ? "青瓷乌龙" : "Oolong Cup"
        case .taroMochi: return isZh ? "芋泥麻薯" : "Taro Mochi"
        case .lemonPunch: return isZh ? "暴打柠檬" : "Citrus Tea"
        case .icedAmericano: return isZh ? "冰美式" : "Americano"
        case .warmLatte: return isZh ? "热拿铁" : "Hot Latte"
        case .grapeOolong: return isZh ? "多肉葡萄" : "Grape Tea"
        }
    }

    var topColorHex: String {
        switch self {
        case .caramelBoba: return "EBC396"
        case .jasmineSilk: return "F6EFE3"
        case .luckinCoconut: return "F3E7D8"
        case .matchaCloud: return "98BF86"
        case .strawberryCheese: return "F7B2BE"
        case .grandpaLychee: return "FAD1D9"
        case .orientPorcelain: return "DCECE8"
        case .taroMochi: return "D4BBE6"
        case .lemonPunch: return "FCE277"
        case .icedAmericano: return "8C532C"
        case .warmLatte: return "D29B6B"
        case .grapeOolong: return "B47BC2"
        }
    }

    var bottomColorHex: String {
        switch self {
        case .caramelBoba: return "9A572C"
        case .jasmineSilk: return "D8B790"
        case .luckinCoconut: return "7B4E32"
        case .matchaCloud: return "497954"
        case .strawberryCheese: return "DC5973"
        case .grandpaLychee: return "EA869B"
        case .orientPorcelain: return "6BA59C"
        case .taroMochi: return "8B65AD"
        case .lemonPunch: return "F0A830"
        case .icedAmericano: return "3B2012"
        case .warmLatte: return "8A4E27"
        case .grapeOolong: return "6B3782"
        }
    }

    var strawColorHex: String {
        switch self {
        case .caramelBoba: return "3F261A"
        case .jasmineSilk: return "C14338"
        case .luckinCoconut: return "1E3E8C"
        case .matchaCloud: return "3D6B4A"
        case .strawberryCheese: return "E25978"
        case .grandpaLychee: return "D95B7A"
        case .orientPorcelain: return "3A7C73"
        case .taroMochi: return "704C94"
        case .lemonPunch: return "4B8B46"
        case .icedAmericano: return "262320"
        case .warmLatte: return "C58A54"
        case .grapeOolong: return "5F2E78"
        }
    }

    var sleeveColorHex: String {
        switch self {
        case .caramelBoba: return "F4DEC3"
        case .jasmineSilk: return "B73B30"
        case .luckinCoconut: return "1D3C85"
        case .matchaCloud: return "EBF4E5"
        case .strawberryCheese: return "FFF0F3"
        case .grandpaLychee: return "FFE4EB"
        case .orientPorcelain: return "2D6D65"
        case .taroMochi: return "EFE5F7"
        case .lemonPunch: return "FFF6CC"
        case .icedAmericano: return "EDE4D8"
        case .warmLatte: return "6C3D21"
        case .grapeOolong: return "F2E3F7"
        }
    }

    var hasPearls: Bool {
        switch self {
        case .caramelBoba, .taroMochi, .grapeOolong: return true
        default: return false
        }
    }

    var hasFoam: Bool {
        switch self {
        case .strawberryCheese, .matchaCloud, .caramelBoba, .warmLatte, .grandpaLychee: return true
        default: return false
        }
    }

    var isHotCup: Bool {
        self == .warmLatte
    }

    var accentEmoji: String {
        switch self {
        case .caramelBoba: return "🧋"
        case .jasmineSilk: return "🍃"
        case .luckinCoconut: return "🥥"
        case .matchaCloud: return "🍵"
        case .strawberryCheese: return "🍓"
        case .grandpaLychee: return "🌸"
        case .orientPorcelain: return "🌿"
        case .taroMochi: return "🍠"
        case .lemonPunch: return "🍋"
        case .icedAmericano: return "🧊"
        case .warmLatte: return "☕️"
        case .grapeOolong: return "🍇"
        }
    }
}

struct DrinkEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var brand: String
    var drinkName: String
    var category: DrinkCategory
    var price: Double
    var sugar: SugarLevel
    var ice: IceLevel
    var rating: Int // 1...5
    var caffeineMg: Int
    var caloriesKcal: Int
    var note: String
    var presetCup: PresetCupStyle
    var frameStyle: StickerFrameStyle
    var customStickerFileName: String?
    var tiltDegrees: Double
    var isSampleData: Bool = false
}

enum PosterTheme: String, CaseIterable, Identifiable {
    case caramelCream = "caramel"
    case matchaPaper = "matcha"
    case berryPolka = "berry"

    var id: String { rawValue }

    func title(_ isZh: Bool) -> String {
        switch self {
        case .caramelCream: return isZh ? "焦糖奶油" : "Caramel"
        case .matchaPaper: return isZh ? "抹茶和纸" : "Matcha"
        case .berryPolka: return isZh ? "草莓波点" : "Berry"
        }
    }

    var bgHex: String {
        switch self {
        case .caramelCream: return "FAF2E6"
        case .matchaPaper: return "EEF5EA"
        case .berryPolka: return "FDF0F3"
        }
    }

    var accentHex: String {
        switch self {
        case .caramelCream: return "6E3F24"
        case .matchaPaper: return "3B6B49"
        case .berryPolka: return "B8435F"
        }
    }

    var chipHex: String {
        switch self {
        case .caramelCream: return "EFE0CC"
        case .matchaPaper: return "DCECD6"
        case .berryPolka: return "F9D7E0"
        }
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        if cleaned.count == 6 {
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        } else {
            (r, g, b) = (250, 245, 236)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}

enum CupTheme {
    static let paperBg = Color(hex: "FAF5EC")
    static let cardBg = Color(hex: "FFFDF9")
    static let borderLine = Color(hex: "EADFD0")
    static let cocoaInk = Color(hex: "3D2618")
    static let caramel = Color(hex: "7A4627")
    static let mutedBrown = Color(hex: "8B7260")
    static let matcha = Color(hex: "588964")
    static let berry = Color(hex: "DF6B83")
    static let warmGold = Color(hex: "E9A93D")
}
