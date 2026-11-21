import SwiftUI
import UIKit

/// 精致手绘风杯子贴纸渲染器（支持真实照片 Vision 抠图贴纸 + 12 款预设艺术杯型 + 4 种手账边框）
struct CupStickerArtView: View {
    let preset: PresetCupStyle
    let frameStyle: StickerFrameStyle
    let customImage: UIImage?
    var brandShort: String = ""
    var size: CGFloat = 54
    var tilt: Double = 0

    var body: some View {
        Group {
            switch frameStyle {
            case .dieCutWhite:
                dieCutContent
            case .polaroid:
                polaroidContent
            case .stamp:
                stampContent
            case .washiTape:
                washiContent
            }
        }
        .rotationEffect(.degrees(tilt))
    }

    @ViewBuilder
    private var coreArt: some View {
        if let customImage {
            Image(uiImage: customImage)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.92, height: size * 0.92)
        } else {
            ProceduralCupIllustration(style: preset, size: size * 0.88)
        }
    }

    private var dieCutContent: some View {
        ZStack {
            if customImage == nil {
                ProceduralCupIllustration(style: preset, size: size * 0.88, outlineOnly: true)
                    .scaleEffect(1.13)
                    .shadow(color: Color.black.opacity(0.14), radius: size * 0.06, x: 0, y: size * 0.04)
            }
            coreArt
                .shadow(color: Color.black.opacity(customImage != nil ? 0.16 : 0.0), radius: size * 0.06, x: 0, y: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    private var polaroidContent: some View {
        VStack(spacing: size * 0.03) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                    .fill(Color(hex: "F8F1E7"))
                coreArt
                    .scaleEffect(0.84)
            }
            .frame(width: size * 0.84, height: size * 0.78)
            Text(brandShort.isEmpty ? preset.accentEmoji : String(brandShort.prefix(4)))
                .font(.system(size: max(7, size * 0.12), weight: .semibold, design: .rounded))
                .foregroundStyle(CupTheme.mutedBrown)
                .lineLimit(1)
        }
        .padding(.top, size * 0.06)
        .padding(.bottom, size * 0.06)
        .padding(.horizontal, size * 0.06)
        .background(
            RoundedRectangle(cornerRadius: size * 0.11, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: size * 0.06, x: 0, y: size * 0.04)
        )
    }

    private var stampContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: max(1.5, size * 0.035), dash: [size * 0.07, size * 0.05]))
                        .foregroundStyle(Color(hex: "DECBB5"))
                )
                .shadow(color: Color.black.opacity(0.11), radius: size * 0.05, x: 0, y: size * 0.03)
            coreArt
                .scaleEffect(0.82)
        }
        .frame(width: size * 0.96, height: size * 1.04)
    }

    private var washiContent: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: size * 0.05, x: 0, y: size * 0.04)
                .overlay(coreArt.scaleEffect(0.86))
                .frame(width: size * 0.94, height: size * 0.96)
                .padding(.top, size * 0.08)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: preset.topColorHex).opacity(0.82))
                .frame(width: size * 0.44, height: size * 0.15)
                .rotationEffect(.degrees(-6))
        }
    }
}

/// 高质感程序化手绘杯子矢量图（支持实体渲染与纯白不干胶底衬渲染）
struct ProceduralCupIllustration: View {
    let style: PresetCupStyle
    let size: CGFloat
    var outlineOnly: Bool = false

    var body: some View {
        Canvas { ctx, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            // 1. 吸管（非热杯）
            if !style.isHotCup {
                var straw = Path()
                let sx = w * 0.56
                straw.move(to: CGPoint(x: sx - w * 0.045, y: h * 0.30))
                straw.addLine(to: CGPoint(x: sx + w * 0.035, y: h * 0.04))
                straw.addLine(to: CGPoint(x: sx + w * 0.115, y: h * 0.06))
                straw.addLine(to: CGPoint(x: sx + w * 0.035, y: h * 0.30))
                straw.closeSubpath()
                ctx.fill(straw, with: .color(outlineOnly ? .white : Color(hex: style.strawColorHex)))
            }

            // 2. 杯身梯形路径
            let topY = h * 0.28
            let botY = h * 0.93
            let topLeft = w * 0.18
            let topRight = w * 0.82
            let botLeft = w * 0.27
            let botRight = w * 0.73

            var cupPath = Path()
            cupPath.move(to: CGPoint(x: topLeft, y: topY))
            cupPath.addLine(to: CGPoint(x: topRight, y: topY))
            cupPath.addLine(to: CGPoint(x: botRight, y: botY - h * 0.04))
            cupPath.addQuadCurve(to: CGPoint(x: botRight - w * 0.06, y: botY), control: CGPoint(x: botRight, y: botY))
            cupPath.addLine(to: CGPoint(x: botLeft + w * 0.06, y: botY))
            cupPath.addQuadCurve(to: CGPoint(x: botLeft, y: botY - h * 0.04), control: CGPoint(x: botLeft, y: botY))
            cupPath.closeSubpath()

            // 3. 穹顶杯盖或热饮杯盖
            let lidPath: Path
            if style.isHotCup {
                var p = Path()
                p.addRoundedRect(in: CGRect(x: w * 0.14, y: h * 0.21, width: w * 0.72, height: h * 0.095), cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
                p.addRoundedRect(in: CGRect(x: w * 0.21, y: h * 0.14, width: w * 0.58, height: h * 0.09), cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
                lidPath = p
            } else {
                var p = Path()
                p.addArc(center: CGPoint(x: w * 0.5, y: topY), radius: w * 0.31, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.closeSubpath()
                lidPath = p
            }

            if outlineOnly {
                ctx.fill(cupPath, with: .color(.white))
                ctx.fill(lidPath, with: .color(.white))
                var rim = Path()
                rim.addRoundedRect(in: CGRect(x: w * 0.14, y: topY - h * 0.03, width: w * 0.72, height: h * 0.065), cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
                ctx.fill(rim, with: .color(.white))
                return
            }

            // 透明穹顶盖光泽
            if !style.isHotCup {
                ctx.fill(lidPath, with: .color(Color.white.opacity(0.76)))
                ctx.stroke(lidPath, with: .color(Color(hex: "DFD3C3")), lineWidth: max(1, w * 0.02))
            }

            // 杯身茶汤渐变
            let teaGrad = Gradient(colors: [Color(hex: style.topColorHex), Color(hex: style.bottomColorHex)])
            ctx.fill(cupPath, with: .linearGradient(teaGrad, startPoint: CGPoint(x: w * 0.5, y: topY), endPoint: CGPoint(x: w * 0.5, y: botY)))

            // 顶层奶盖波浪
            if style.hasFoam {
                var foam = Path()
                foam.move(to: CGPoint(x: topLeft + w * 0.01, y: topY))
                foam.addLine(to: CGPoint(x: topRight - w * 0.01, y: topY))
                foam.addLine(to: CGPoint(x: topRight - w * 0.03, y: topY + h * 0.14))
                foam.addQuadCurve(to: CGPoint(x: w * 0.58, y: topY + h * 0.13), control: CGPoint(x: w * 0.68, y: topY + h * 0.19))
                foam.addQuadCurve(to: CGPoint(x: w * 0.35, y: topY + h * 0.14), control: CGPoint(x: w * 0.46, y: topY + h * 0.08))
                foam.addQuadCurve(to: CGPoint(x: topLeft + w * 0.03, y: topY + h * 0.12), control: CGPoint(x: w * 0.25, y: topY + h * 0.18))
                foam.closeSubpath()
                ctx.fill(foam, with: .color(Color(hex: "FFFBF3").opacity(0.92)))
            }

            // 底部黑糖珍珠/波波
            if style.hasPearls {
                let pearlCoords: [(CGFloat, CGFloat)] = [
                    (0.36, 0.85), (0.45, 0.87), (0.55, 0.86), (0.64, 0.84),
                    (0.40, 0.79), (0.50, 0.80), (0.60, 0.79)
                ]
                let pr = w * 0.048
                for (px, py) in pearlCoords {
                    let rect = CGRect(x: w * px - pr, y: h * py - pr, width: pr * 2, height: pr * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: "2B1810").opacity(0.85)))
                    let shine = CGRect(x: w * px - pr * 0.45, y: h * py - pr * 0.55, width: pr * 0.45, height: pr * 0.45)
                    ctx.fill(Path(ellipseIn: shine), with: .color(Color.white.opacity(0.45)))
                }
            }

            // 中部腰封贴纸杯套
            var sleeve = Path()
            let sTop = h * 0.48
            let sBot = h * 0.68
            sleeve.move(to: CGPoint(x: w * 0.21, y: sTop))
            sleeve.addLine(to: CGPoint(x: w * 0.79, y: sTop))
            sleeve.addLine(to: CGPoint(x: w * 0.76, y: sBot))
            sleeve.addLine(to: CGPoint(x: w * 0.24, y: sBot))
            sleeve.closeSubpath()
            ctx.fill(sleeve, with: .color(Color(hex: style.sleeveColorHex).opacity(0.92)))

            // 腰封中央徽章小圆点
            let dotR = w * 0.065
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - dotR, y: (sTop + sBot) * 0.5 - dotR, width: dotR * 2, height: dotR * 2)),
                     with: .color(Color.white.opacity(0.85)))

            // 左侧玻璃高光条
            var gloss = Path()
            gloss.addRoundedRect(in: CGRect(x: w * 0.25, y: h * 0.35, width: w * 0.055, height: h * 0.42), cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(gloss, with: .color(Color.white.opacity(0.32)))

            // 杯口边缘与热饮盖
            if style.isHotCup {
                ctx.fill(lidPath, with: .color(Color(hex: "FFF9F0")))
                ctx.stroke(lidPath, with: .color(Color(hex: "D9C7B2")), lineWidth: max(1, w * 0.02))
            } else {
                var rim = Path()
                rim.addRoundedRect(in: CGRect(x: w * 0.14, y: topY - h * 0.025, width: w * 0.72, height: h * 0.058), cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
                ctx.fill(rim, with: .color(Color.white))
                ctx.stroke(rim, with: .color(Color(hex: "DFD1C0")), lineWidth: max(1, w * 0.018))
            }

            // 柔和外描边提升手绘精致度
            ctx.stroke(cupPath, with: .color(Color(hex: "543927").opacity(0.28)), lineWidth: max(1, w * 0.018))
        }
        .frame(width: size, height: size)
    }
}

/// 原生相机采集器封装（安全检测设备是否支持相机，模拟器自动优雅降级）
struct CameraCaptureView: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.onPicked(img)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
