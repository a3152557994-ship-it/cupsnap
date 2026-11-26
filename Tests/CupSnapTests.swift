import XCTest
@testable import CupSnap

final class CupSnapTests: XCTestCase {
    func testReceiptParserRecognizesNicheBrandsAndFields() {
        let sample = """
        爷爷不泡茶 (杭州西湖店)
        取餐号 B109
        荔枝冰酿 (大杯)
        三分糖 / 去冰 / 加脆波波
        实付金额 ¥17.50
        """
        let parsed = ReceiptOCREngine.shared.parseText(sample)
        XCTAssertEqual(parsed.brand, "爷爷不泡茶")
        XCTAssertTrue(parsed.drinkName.contains("荔枝冰酿"))
        XCTAssertEqual(parsed.price, 17.5, accuracy: 0.01)
        XCTAssertEqual(parsed.sugar, .thirty)
        XCTAssertEqual(parsed.ice, .noIce)
        XCTAssertEqual(parsed.suggestedCup, .grandpaLychee)
    }

    func testReceiptParserRecognizesDongfangMolanAndCoffee() {
        let molan = ReceiptOCREngine.shared.parseText("东方茉兰\n青瓷乌龙轻乳茶\n七分糖 少冰\n合计￥19")
        XCTAssertEqual(molan.brand, "东方茉兰")
        XCTAssertEqual(molan.price, 19.0, accuracy: 0.01)
        XCTAssertEqual(molan.sugar, .seventy)
        XCTAssertEqual(molan.ice, .lessIce)

        let luckin = ReceiptOCREngine.shared.parseText("瑞幸咖啡 luckin coffee\n生椰拿铁\n不另外加糖 冰\n实付 ¥9.90")
        XCTAssertEqual(luckin.brand, "瑞幸咖啡")
        XCTAssertEqual(luckin.category, .coffee)
        XCTAssertEqual(luckin.price, 9.9, accuracy: 0.01)
        XCTAssertEqual(luckin.sugar, .zero)
    }

    @MainActor
    func testBackupExportAndRestorePreservesRecords() {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DrinkStore(customDirectory: tmp)
        store.clearSampleEntries()

        let entry = DrinkEntry(
            date: Date(),
            brand: "霸王茶姬",
            drinkName: "伯牙绝弦",
            category: .milkTea,
            price: 20.0,
            sugar: .thirty,
            ice: .lessIce,
            rating: 5,
            caffeineMg: 115,
            caloriesKcal: 240,
            note: "超好喝",
            presetCup: .jasmineSilk,
            frameStyle: .dieCutWhite,
            customStickerFileName: nil,
            tiltDegrees: -3.0,
            isSampleData: false
        )
        store.addEntry(entry)
        guard let json = store.exportBackupJSON() else {
            XCTFail("Expected non-nil backup JSON")
            return
        }

        let tmp2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let restoredStore = DrinkStore(customDirectory: tmp2)
        restoredStore.clearSampleEntries()
        let importedCount = restoredStore.importBackupJSON(json)
        XCTAssertEqual(importedCount, 1)
        XCTAssertEqual(restoredStore.entries.first?.brand, "霸王茶姬")
        XCTAssertEqual(restoredStore.entries.first?.drinkName, "伯牙绝弦")

        let csv = restoredStore.exportCSVString(isZh: true)
        XCTAssertTrue(csv.contains("霸王茶姬"))
        XCTAssertTrue(csv.contains("伯牙绝弦"))

        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: tmp2)
    }

    func testBrandCatalogExceeds108RealChainsIncludingHKTW() {
        let catalog = ReceiptOCREngine.shared.brandCatalog
        XCTAssertGreaterThanOrEqual(catalog.count, 108, "brandCatalog must cover 108+ real chains")
        let uniqueNames = Set(catalog.map(\.canonical))
        XCTAssertEqual(uniqueNames.count, catalog.count, "All canonical brand names must be unique")

        // Traditional Chinese Taiwan / HK receipt test
        let twReceipt = """
        可不可熟成紅茶 (台北信義店)
        春芽冷露 (大杯)
        微糖 / 去冰
        應付金額
        $45
        儲值卡餘額 $320
        """
        let parsedTW = ReceiptOCREngine.shared.parseText(twReceipt)
        XCTAssertEqual(parsedTW.brand, "可不可熟成红茶")
        XCTAssertEqual(parsedTW.drinkName, "春芽冷露")
        XCTAssertEqual(parsedTW.price, 45.0, accuracy: 0.01)
        XCTAssertEqual(parsedTW.sugar, .thirty)
        XCTAssertEqual(parsedTW.ice, .noIce)
    }

    func testPriceParserIgnoresStoredBalanceChangeAndDiscounts() {
        let receiptWithBalance = """
        霸王茶姬 CHAGEE
        单号：#8092
        桂馥兰香 (大杯) ¥20.00
        会员立减优惠 -¥3.50
        应收金额
        ¥16.50
        储值卡余额 ¥286.40
        找零 ¥0.00
        """
        let parsed = ReceiptOCREngine.shared.parseText(receiptWithBalance)
        XCTAssertEqual(parsed.brand, "霸王茶姬")
        XCTAssertEqual(parsed.drinkName, "桂馥兰香")
        XCTAssertEqual(parsed.price, 16.50, accuracy: 0.01, "Must pick 应收/实付 16.50 instead of 储值卡余额 286.40 or 找零 0.00")
    }

    func testUnlabeledSugarReturnsUnspecifiedAndSkipsWifiRemarkLines() {
        let coffeeReceipt = """
        Manner Coffee (静安寺店)
        Wi-Fi: Manner_Guest / 密码: 88886666
        备注：不要吸管放前台桌子上谢谢
        冰美式 (大杯)
        去冰
        实付 ¥15.00
        储值余额 ¥135.00
        """
        let parsed = ReceiptOCREngine.shared.parseText(coffeeReceipt)
        XCTAssertEqual(parsed.brand, "Manner Coffee")
        XCTAssertEqual(parsed.drinkName, "冰美式")
        XCTAssertEqual(parsed.price, 15.0, accuracy: 0.01)
        XCTAssertEqual(parsed.sugar, .unspecified, "Missing sugar on receipt must default to .unspecified ('未标注') rather than .thirty")
        XCTAssertEqual(parsed.sugar.title(true), "未标注")

        // Fallback when drink is an unknown specialty name surrounded by Wi-Fi & remarks
        let obscureDrinkReceipt = """
        春水堂
        Wi-Fi密码：chunshuitang88
        备注：多给两包纸巾
        观音韵味冰茶
        实付 ¥26.00
        """
        let parsed2 = ReceiptOCREngine.shared.parseText(obscureDrinkReceipt)
        XCTAssertEqual(parsed2.brand, "春水堂")
        XCTAssertEqual(parsed2.drinkName, "观音韵味冰茶")
        XCTAssertEqual(parsed2.sugar, .unspecified)
    }
}
