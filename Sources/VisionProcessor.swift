import Foundation
import CoreImage
import CoreVideo
import Accelerate.vImage

final class VisionProcessor {
    private let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
    private var buffer: [UInt8]?

    func downsample(_ pixelBuffer: CVPixelBuffer, size: Int) -> [[Float]] {
        precondition(size > 0)

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let scaleX = CGFloat(size) / extent.width
        let scaleY = CGFloat(size) / extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let outWidth = size
        let outHeight = size
        let bytesPerPixel = 4
        let bytesPerRow = outWidth * bytesPerPixel
        if buffer == nil || buffer!.count != outHeight * bytesPerRow {
            buffer = [UInt8](repeating: 0, count: outHeight * bytesPerRow)
        }

        buffer!.withUnsafeMutableBytes { ptr in
            let colorSpace = ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(.premultipliedFirst)
            do {
                try context.render(scaled,
                                   toBitmap: ptr.baseAddress!,
                                   rowBytes: bytesPerRow,
                                   bounds: CGRect(x: 0, y: 0, width: outWidth, height: outHeight),
                                   format: .BGRA8,
                                   colorSpace: colorSpace)
            } catch {
                print("Render failed: \(error.localizedDescription)")
                return Array(repeating: Array(repeating: Float(0), count: size), count: size)
            }
        }

        var luminance = [Float](repeating: 0, count: outWidth * outHeight)
        var bgraBuffer = vImage_Buffer(data: &buffer!, height: UInt(outHeight), width: UInt(outWidth), rowBytes: bytesPerRow)
        var lumaBuffer = vImage_Buffer(data: &luminance, height: UInt(outHeight), width: UInt(outWidth), rowBytes: outWidth * MemoryLayout<Float>.size)
        let rCoef: Float = 0.299, gCoef: Float = 0.587, bCoef: Float = 0.114
        vImageConvert_ARGB8888toPlanarF(&bgraBuffer, &lumaBuffer, rCoef, gCoef, bCoef, 0, 0)

        var grid = Array(repeating: Array(repeating: Float(0), count: outWidth), count: outHeight)
        for y in 0..<outHeight {
            for x in 0..<outWidth {
                grid[y][x] = max(0, min(1, luminance[y * outWidth + x]))
            }
        }
        return grid
    }

    func column(from grid: [[Float]], x: Int) -> [Float] {
        let h = grid.count
        guard h > 0 else { return [] }
        let w = grid[0].count
        guard x >= 0 && x < w else { return [] }
        var col = [Float](repeating: 0, count: h)
        for y in 0..<h {
            col[y] = grid[y][x]
        }
        return col
    }
}
