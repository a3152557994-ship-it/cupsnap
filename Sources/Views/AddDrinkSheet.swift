import PhotosUI
import SwiftUI
import UIKit

struct AddDrinkSheet: View {
    @ObservedObject var store: DrinkStore
    @ObservedObject var l10n: L10n
    var initialDate: Date = Date()
    var editingEntry: DrinkEntry? = nil
    var prefillSampleReceiptIndex: Int? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var brand: String = ""
    @State private var drinkName: String = ""
    @State private var category: DrinkCategory = .milkTea
    @State private var priceText: String = "18"
    @State private var sugar: SugarLevel = .thirty
    @State private var ice: IceLevel = .lessIce
    @State private var rating: Int = 5
    @State private var note: String = ""
    @State private var presetCup: PresetCupStyle = .jasmineSilk
    @State private var frameStyle: StickerFrameStyle = .dieCutWhite
    @State private var customStickerImage: UIImage? = nil

    @State private var cupPhotoPickerItem: PhotosPickerItem?
    @State private var receiptPhotoPickerItem: PhotosPickerItem?
    @State private var showCupCamera = false
    @State private var showReceiptCamera = false

    @State private var isProcessingSticker = false
    @State private var isProcessingOCR = false
    @State private var ocrBannerMessage: String? = nil

    private let quickBrands = ["霸王茶姬", "瑞幸咖啡", "喜茶", "爷爷不泡茶", "东方茉兰", "茶颜悦色", "古茗", "茶百道", "阿嬷手作", "星巴克", "Manner Coffee", "蜜雪冰城"]

    var body: some View {
        NavigationStack {
            ZStack {
                CupTheme.paperBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        stickerPreviewStudioCard
                        offlineReceiptOCRCard
                        drinkDetailsFormCard
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle(editingEntry == nil ? l10n.t("贴下这一杯", "New Cup Sticker") : l10n.t("编辑贴纸", "Edit Sticker"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.t("取消", "Cancel")) { dismiss() }
                        .foregroundStyle(CupTheme.mutedBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(l10n.t("贴上日历", "Stick It")) { saveEntry() }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.caramel)
                }
            }
            .onAppear { loadInitialState() }
            .onChange(of: cupPhotoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await handleCupPhotoPicked(newItem) }
            }
            .onChange(of: receiptPhotoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await handleReceiptPhotoPicked(newItem) }
            }
            .sheet(isPresented: $showCupCamera) {
                CameraCaptureView { image in
                    Task { await processRawCupImage(image) }
                }
            }
            .sheet(isPresented: $showReceiptCamera) {
                CameraCaptureView { image in
                    Task { await processRawReceiptImage(image) }
                }
            }
        }
    }

    // 区块 1：AI 一键抠杯做白边贴纸工作台
    private var stickerPreviewStudioCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label(l10n.t("1. 拍杯子自动抠白边贴纸", "1. Auto Cutout Cup Sticker"), systemImage: "wand.and.stars")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Spacer()
                Text(l10n.t("本地 AI · 0 联网", "On-Device AI"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CupTheme.matcha)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(CupTheme.matcha.opacity(0.14)))
            }

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: "F4EAD9"))
                        .frame(width: 116, height: 116)
                    if isProcessingSticker {
                        ProgressView()
                            .tint(CupTheme.caramel)
                    } else {
                        CupStickerArtView(
                            preset: presetCup,
                            frameStyle: frameStyle,
                            customImage: customStickerImage,
                            brandShort: brand,
                            size: 92,
                            tilt: -3
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        Button {
                            showCupCamera = true
                        } label: {
                            Label(l10n.t("拍杯子", "Camera"), systemImage: "camera.fill")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CupTheme.caramel))
                        }

                        PhotosPicker(selection: $cupPhotoPickerItem, matching: .images) {
                            Label(l10n.t("相册抠图", "Photos"), systemImage: "photo.on.rectangle")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(CupTheme.caramel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(hex: "F3E5D4"))
                                )
                        }
                    }

                    // 4 种贴纸边框样式切换
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(StickerFrameStyle.allCases) { st in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { frameStyle = st }
                                } label: {
                                    Text(st.title(l10n.isZh))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(frameStyle == st ? .white : CupTheme.cocoaInk)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(frameStyle == st ? CupTheme.cocoaInk : Color(hex: "EFE6DA")))
                                }
                            }
                        }
                    }

                    if customStickerImage != nil {
                        Button(l10n.t("改回手绘杯子贴纸", "Reset to Illustrated Cup")) {
                            customStickerImage = nil
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CupTheme.berry)
                    } else {
                        Text(l10n.t("选任意杯子照自动去除背景并加手工白边", "Removes background & adds crisp vinyl sticker border offline"))
                            .font(.system(size: 11))
                            .foregroundStyle(CupTheme.mutedBrown)
                    }
                }
            }

            // 12 款手绘杯型横向快选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PresetCupStyle.allCases) { style in
                        Button {
                            customStickerImage = nil
                            presetCup = style
                        } label: {
                            VStack(spacing: 3) {
                                CupStickerArtView(preset: style, frameStyle: .dieCutWhite, customImage: nil, size: 42)
                                Text(style.label(l10n.isZh))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(presetCup == style && customStickerImage == nil ? CupTheme.caramel : CupTheme.mutedBrown)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(presetCup == style && customStickerImage == nil ? Color(hex: "F5E6D3") : Color(hex: "FAF6F0"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(presetCup == style && customStickerImage == nil ? CupTheme.caramel : Color.clear, lineWidth: 1.4)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(cardSurface)
    }

    // 区块 2：离线 AI 拍小票 / 外卖截图自动填表（彻底碾压竞品虚假 AI 差评）
    private var offlineReceiptOCRCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(l10n.t("2. 拍小票 / 外卖截图 0.3 秒填表", "2. Scan Receipt / Order Screenshot"), systemImage: "doc.text.viewfinder")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(CupTheme.cocoaInk)
                Spacer()
                if isProcessingOCR {
                    ProgressView().scaleEffect(0.8)
                }
            }

            HStack(spacing: 8) {
                Button {
                    showReceiptCamera = true
                } label: {
                    Label(l10n.t("拍杯身标签", "Scan Label"), systemImage: "viewfinder")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CupTheme.matcha))
                }

                PhotosPicker(selection: $receiptPhotoPickerItem, matching: .images) {
                    Label(l10n.t("导入外卖截图", "Order Screenshot"), systemImage: "text.viewfinder")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(CupTheme.matcha)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CupTheme.matcha.opacity(0.14)))
                }
            }

            // 3 个真实小票样例一键演示（0 门槛体验真实解析引擎）
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.t("手边没小票？点一下秒试离线识别（含爷爷不泡茶/霸王茶姬/瑞幸）：", "Try instant offline OCR with sample receipts:"))
                    .font(.system(size: 11))
                    .foregroundStyle(CupTheme.mutedBrown)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ReceiptOCREngine.shared.sampleReceipts) { sample in
                            Button {
                                applySampleReceipt(sample)
                            } label: {
                                Text(l10n.isZh ? sample.titleZh : sample.titleEn)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(CupTheme.caramel)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color(hex: "F6EBDC")))
                            }
                        }
                    }
                }
            }

            if let ocrBannerMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(CupTheme.matcha)
                    Text(ocrBannerMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CupTheme.matcha)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(CupTheme.matcha.opacity(0.12)))
            }
        }
        .padding(14)
        .background(cardSurface)
    }

    // 区块 3：极简信息微调卡片
    private var drinkDetailsFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(l10n.t("3. 饮品信息（支持任意小众自填品牌）", "3. Drink Details (Any Brand Welcome)"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(CupTheme.cocoaInk)

            // 品牌快选标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(quickBrands, id: \.self) { b in
                        Button {
                            brand = b
                        } label: {
                            Text(b)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(brand == b ? .white : CupTheme.cocoaInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(brand == b ? CupTheme.caramel : Color(hex: "F3EAE0")))
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("品牌/店名", "Brand"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CupTheme.mutedBrown)
                    TextField(l10n.t("例：爷爷不泡茶", "e.g. CHAGEE"), text: $brand)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "FAF5EC")))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("饮品名", "Drink Name"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CupTheme.mutedBrown)
                    TextField(l10n.t("例：荔枝冰酿", "e.g. Jasmine Tea"), text: $drinkName)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "FAF5EC")))
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("实付金额", "Price"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CupTheme.mutedBrown)
                    TextField("18", text: $priceText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "FAF5EC")))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("饮用日期", "Date"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CupTheme.mutedBrown)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .padding(.vertical, 4)
                }
            }

            // 品类
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.t("品类", "Category"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CupTheme.mutedBrown)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(DrinkCategory.allCases) { c in
                            Button { category = c } label: {
                                Text(c.title(l10n.isZh))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(category == c ? .white : CupTheme.cocoaInk)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(category == c ? Color(hex: c.badgeColorHex) : Color(hex: "F3EAE0")))
                            }
                        }
                    }
                }
            }

            // 糖度 + 冰度
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.t("糖度", "Sugar"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CupTheme.mutedBrown)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(SugarLevel.allCases) { s in
                            Button { sugar = s } label: {
                                Text(s.title(l10n.isZh))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(sugar == s ? .white : CupTheme.cocoaInk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(sugar == s ? CupTheme.berry : Color(hex: "F3EAE0")))
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.t("温度 / 冰度", "Ice / Temp"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CupTheme.mutedBrown)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(IceLevel.allCases) { i in
                            Button { ice = i } label: {
                                Text(i.title(l10n.isZh))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ice == i ? .white : CupTheme.cocoaInk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(ice == i ? Color(hex: "5A8DB8") : Color(hex: "F3EAE0")))
                            }
                        }
                    }
                }
            }

            // 好喝打分
            HStack {
                Text(l10n.t("回购指数", "Rating"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CupTheme.mutedBrown)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Button { rating = star } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundStyle(star <= rating ? CupTheme.warmGold : CupTheme.borderLine)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.t("一句心情 / 口感备注", "Mood / Tasting Note"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CupTheme.mutedBrown)
                TextField(l10n.t("例：少甜去冰刚刚好，下次还点！", "e.g. 30% sugar tastes awesome!"), text: $note)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "FAF5EC")))
            }
        }
        .padding(14)
        .background(cardSurface)
    }

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(CupTheme.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(CupTheme.borderLine, lineWidth: 1))
    }

    private func loadInitialState() {
        date = initialDate
        if let e = editingEntry {
            date = e.date
            brand = e.brand
            drinkName = e.drinkName
            category = e.category
            priceText = String(format: "%.1f", e.price)
            sugar = e.sugar
            ice = e.ice
            rating = e.rating
            note = e.note
            presetCup = e.presetCup
            frameStyle = e.frameStyle
            customStickerImage = store.loadCustomSticker(fileName: e.customStickerFileName)
        } else if let sampleIdx = prefillSampleReceiptIndex,
                  sampleIdx < ReceiptOCREngine.shared.sampleReceipts.count {
            applySampleReceipt(ReceiptOCREngine.shared.sampleReceipts[sampleIdx])
        }
    }

    private func applySampleReceipt(_ sample: ReceiptSamplePreset) {
        let parsed = ReceiptOCREngine.shared.parseText(sample.rawReceiptText)
        withAnimation(.spring(response: 0.28)) {
            brand = parsed.brand
            drinkName = parsed.drinkName
            category = parsed.category
            priceText = String(format: "%.1f", parsed.price)
            sugar = parsed.sugar
            ice = parsed.ice
            presetCup = sample.cupStyle
            ocrBannerMessage = l10n.t(
                "已离线识别：\(parsed.brand) · \(parsed.drinkName) · ¥\(String(format: "%.1f", parsed.price)) · \(parsed.sugar.title(true))/\(parsed.ice.title(true))",
                "Parsed offline: \(parsed.brand) · \(parsed.drinkName) · \(parsed.sugar.shortLabel)"
            )
        }
    }

    private func handleCupPhotoPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        await processRawCupImage(img)
    }

    private func processRawCupImage(_ image: UIImage) async {
        isProcessingSticker = true
        let sticker = await CupStickerEngine.shared.makeDieCutSticker(from: image)
        await MainActor.run {
            self.customStickerImage = sticker
            self.isProcessingSticker = false
        }
    }

    private func handleReceiptPhotoPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        await processRawReceiptImage(img)
    }

    private func processRawReceiptImage(_ image: UIImage) async {
        isProcessingOCR = true
        let parsed = await ReceiptOCREngine.shared.recognizeImage(image)
        await MainActor.run {
            brand = parsed.brand
            drinkName = parsed.drinkName
            category = parsed.category
            priceText = String(format: "%.1f", parsed.price)
            sugar = parsed.sugar
            ice = parsed.ice
            presetCup = parsed.suggestedCup
            ocrBannerMessage = l10n.t(
                "离线识别完成：\(parsed.brand) · \(parsed.drinkName)（可随时微调）",
                "Offline OCR filled: \(parsed.brand) · \(parsed.drinkName)"
            )
            isProcessingOCR = false
        }
    }

    private func saveEntry() {
        let finalBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? l10n.t("今日好茶", "Daily Sip") : brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDrink = drinkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? presetCup.label(l10n.isZh) : drinkName.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 18.0
        let calories = Int(Double(category.defaultCaloriesKcal) * sugar.calorieMultiplier)
        let caffeine = category.defaultCaffeineMg

        if var existing = editingEntry {
            existing.date = date
            existing.brand = finalBrand
            existing.drinkName = finalDrink
            existing.category = category
            existing.price = max(0, price)
            existing.sugar = sugar
            existing.ice = ice
            existing.rating = rating
            existing.caffeineMg = caffeine
            existing.caloriesKcal = calories
            existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.presetCup = presetCup
            existing.frameStyle = frameStyle
            existing.isSampleData = false
            store.updateEntry(existing, customStickerImage: customStickerImage)
        } else {
            let tilts: [Double] = [-5.0, -3.0, 2.5, 4.5, -4.0, 3.5]
            let newItem = DrinkEntry(
                date: date,
                brand: finalBrand,
                drinkName: finalDrink,
                category: category,
                price: max(0, price),
                sugar: sugar,
                ice: ice,
                rating: rating,
                caffeineMg: caffeine,
                caloriesKcal: calories,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                presetCup: presetCup,
                frameStyle: frameStyle,
                customStickerFileName: nil,
                tiltDegrees: tilts[store.entries.count % tilts.count],
                isSampleData: false
            )
            store.addEntry(newItem, customStickerImage: customStickerImage)
        }
        dismiss()
    }
}
