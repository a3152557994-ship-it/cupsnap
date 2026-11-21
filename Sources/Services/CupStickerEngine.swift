import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit
import Vision

/// 100% 离线端侧 AI 抠图贴纸引擎：
/// 调用 Apple Vision VNGenerateForegroundInstanceMaskRequest（iOS 17+ 原生免费无网络）
/// 自动提取杯子主体并合成「手工奶油白边 + 柔和贴纸阴影」不干胶贴纸。
final class CupStickerEngine {
    static let shared = CupStickerEngine()
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func makeDieCutSticker(from rawImage: UIImage) async -> UIImage {
        let normalized = normalizeOrientationAndResize(rawImage, maxDimension: 900)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let cutout = self.visionCutoutAndOutline(normalized) {
                    continuation.resume(returning: cutout)
                } else {
                    continuation.resume(returning: self.roundedPolaroidFallback(normalized))
                }
            }
        }
    }

    private func visionCutoutAndOutline(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let inputCI = CIImage(cgImage: cgImage)

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let maskBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
            let maskCI = CIImage(cvPixelBuffer: maskBuffer)

            // 1. 抠出前景主体（透明底）
            let blend = CIFilter.blendWithMask()
            blend.inputImage = inputCI
            blend.backgroundImage = CIImage.empty()
            blend.maskImage = maskCI
            guard let subjectCI = blend.outputImage else { return nil }

            // 2. 膨胀蒙版制作不干胶纯白手工描边
            let borderWidth = max(14.0, Float(min(inputCI.extent.width, inputCI.extent.height)) * 0.032)
            let dilate = CIFilter.morphologyMaximum()
            dilate.inputImage = maskCI
            dilate.radius = borderWidth
            guard let dilatedMask = dilate.outputImage else { return nil }

            let whiteSolid = CIImage(color: CIColor(red: 1.0, green: 0.996, blue: 0.985, alpha: 1.0))
                .cropped(to: dilatedMask.extent.insetBy(dx: -CGFloat(borderWidth), dy: -CGFloat(borderWidth)))

            let outlineBlend = CIFilter.blendWithMask()
            outlineBlend.inputImage = whiteSolid
            outlineBlend.backgroundImage = CIImage.empty()
            outlineBlend.maskImage = dilatedMask
            guard let outlineCI = outlineBlend.outputImage else { return nil }

            // 3. 把前景杯子叠在纯白描边之上
            let composite = subjectCI.composited(over: outlineCI)

            // 4. 紧致裁切透明外框，保证贴到日历格子上饱满清晰
            guard let fullCG = ciContext.createCGImage(composite, from: composite.extent) else { return nil }
            return trimTransparentBounds(UIImage(cgImage: fullCG), padding: 12) ?? UIImage(cgImage: fullCG)
        } catch {
            return nil
        }
    }

    private func roundedPolaroidFallback(_ image: UIImage) -> UIImage {
        let size = CGSize(width: 520, height: 520)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let outerRect = CGRect(x: 18, y: 18, width: 484, height: 484)
            let outerPath = UIBezierPath(roundedRect: outerRect, cornerRadius: 56)
            UIColor(red: 1.0, green: 0.996, blue: 0.985, alpha: 1.0).setFill()
            outerPath.fill()

            let innerRect = outerRect.insetBy(dx: 22, dy: 22)
            let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 38)
            ctx.cgContext.saveGState()
            innerPath.addClip()

            let aspect = image.size.width / max(1, image.size.height)
            var drawRect = innerRect
            if aspect > 1 {
                let w = innerRect.height * aspect
                drawRect = CGRect(x: innerRect.midX - w / 2, y: innerRect.minY, width: w, height: innerRect.height)
            } else {
                let h = innerRect.width / max(0.01, aspect)
                drawRect = CGRect(x: innerRect.minX, y: innerRect.midY - h / 2, width: innerRect.width, height: h)
            }
            image.draw(in: drawRect)
            ctx.cgContext.restoreGState()
        }
    }

    private func normalizeOrientationAndResize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        let scale = maxSide > maxDimension ? maxDimension / maxSide : 1.0
        let newSize = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func trimTransparentBounds(_ image: UIImage, padding: Int) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in stride(from: 0, to: height, by: 2) {
            let rowStart = y * bytesPerRow
            for x in stride(from: 0, to: width, by: 2) {
                if data[rowStart + x * 4 + 3] > 20 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        guard minX < maxX && minY < maxY else { return nil }
        let cropRect = CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(width, maxX + padding) - max(0, minX - padding),
            height: min(height, maxY + padding) - max(0, minY - padding)
        )
        guard let cropped = cg.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped)
    }
}
