import Foundation
import Combine
import CoreVideo

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
    private var grid: [[Float]] = []
    private var columnIndex: Int = 0

    private var timer: Timer?

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

    // MARK: - CameraManagerDelegate
    nonisolated func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer) {
        // Update latest buffer
        latestPixelBuffer = pixelBuffer
    }

    func cameraManager(_ manager: CameraManager, didChangeRunning isRunning: Bool) {
        self.isRunning = isRunning
        self.statusText = isRunning ? "Running" : "Stopped"
    }

    func cameraManager(_ manager: CameraManager, didFail error: Error) {
        self.statusText = "Error: \(error.localizedDescription)"
    }

    // MARK: - Timer logic
    private func startTimer() {
        updateTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimer() {
        timer?.invalidate()
        let cps = max(1.0, columnsPerSecond)
        let interval = 1.0 / cps
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard let pb = latestPixelBuffer else { return }
        // Downsample to grid
        let n = max(8, min(64, gridSize))
        grid = vision.downsample(pb, size: n)

        // Wrap column index
        let width = grid.first?.count ?? 0
        if width == 0 { return }
        if columnIndex >= width { columnIndex = 0 }

        let col = vision.column(from: grid, x: columnIndex)
        columnIndex += 1

        // Play sweep for this column
        HapticManager.shared.playSweep(intensities: col, totalDuration: max(0.06, 1.0 / columnsPerSecond))
    }
}
