import Foundation
import Combine
import CoreVideo
import QuartzCore

@MainActor
final class HapticVisionViewModel: NSObject, ObservableObject, CameraManagerDelegate {
    @Published var isRunning: Bool = false
    @Published var statusText: String = "Idle"
    @Published var columnsPerSecond: Double = 12 {
        didSet { updateTimer() }
    }
    @Published var gridSize: Int = 32 {
        didSet { /* will affect next frame processing */ }
    }

    private let camera = CameraManager()
    private let vision = VisionProcessor()
    private var latestPixelBuffer: CVPixelBuffer?
    private let bufferLock = NSLock()
    private var lastProcessedFrame: CMTime?
    private var cachedGrid: [[Float]]?
    private var columnIndex: Int = 0
    private var displayLink: CADisplayLink?

    override init() {
        super.init()
        camera.delegate = self
    }

    func start() {
        statusText = "Starting…"
        camera.start()
        startTimer()
    }

    func stop() {
        camera.stop()
        stopTimer()
        isRunning = false
        statusText = "Stopped"
    }

    nonisolated func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer) {
        bufferLock.lock()
        latestPixelBuffer = pixelBuffer
        bufferLock.unlock()
    }

    func cameraManager(_ manager: CameraManager, didChangeRunning isRunning: Bool) {
        self.isRunning = isRunning
        self.statusText = isRunning ? "Running" : "Stopped"
    }

    func cameraManager(_ manager: CameraManager, didFail error: Error) {
        self.statusText = "Error: \(error.localizedDescription)"
    }

    private func startTimer() {
        stopTimer()
        let cps = max(1.0, columnsPerSecond)
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFramesPerSecond = Int(cps)
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        bufferLock.lock()
        guard let pb = latestPixelBuffer else {
            bufferLock.unlock()
            return
        }
        bufferLock.unlock()

        if let sampleBuffer = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: nil,
            sampleTiming: nil
        ) {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if lastProcessedFrame != timestamp {
                let n = max(8, min(64, gridSize))
                cachedGrid = vision.downsample(pb, size: n)
                lastProcessedFrame = timestamp
            }
        }

        guard let grid = cachedGrid, !grid.isEmpty else { return }
        let width = grid.first?.count ?? 0
        if width == 0 { return }
        if columnIndex >= width { columnIndex = 0 }

        let col = vision.column(from: grid, x: columnIndex)
        columnIndex += 1

        HapticManager.shared.playSweep(intensities: col, totalDuration: min(0.12, max(0.04, 0.8 / columnsPerSecond)))
    }
}
