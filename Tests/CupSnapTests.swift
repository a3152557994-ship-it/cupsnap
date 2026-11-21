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
}
