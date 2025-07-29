import Foundation
import CoreImage
import CoreVideo
import Accelerate

final class VisionProcessor {
    private let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

    /// Downsample the pixel buffer to an NxN luminance grid (0..1).
    func downsample(_ pixelBuffer: CVPixelBuffer, size: Int) -> [[Float]] {
        precondition(size > 0)

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let scaleX = CGFloat(size) / extent.width
        let scaleY = CGFloat(size) / extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Render to a small BGRA buffer
        let outWidth = size
        let outHeight = size
        let bytesPerPixel = 4
        let bytesPerRow = outWidth * bytesPerPixel
        var data = [UInt8](repeating: 0, count: outHeight * bytesPerRow)

        data.withUnsafeMutableBytes { ptr in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(.premultipliedFirst)
            context.render(scaled,
                           toBitmap: ptr.baseAddress!,
                           rowBytes: bytesPerRow,
                           bounds: CGRect(x: 0, y: 0, width: outWidth, height: outHeight),
                           format: .BGRA8,
                           colorSpace: colorSpace)
        }

        // Convert BGRA to luminance (simple luma)
        var grid = Array(repeating: Array(repeating: Float(0), count: outWidth), count: outHeight)
        var idx = 0
        for y in 0..<outHeight {
            for x in 0..<outWidth {
                let b = Float(data[idx + 0])
                let g = Float(data[idx + 1])
                let r = Float(data[idx + 2])
                // ITU BT.601 approx
                let luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                grid[y][x] = max(0, min(1, luma))
                idx += 4
            }
        }
        return grid
    }

    /// Extract a column (as an array of intensities top->bottom) from the grid.
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
