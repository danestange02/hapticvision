import Foundation
import AVFoundation
import CoreVideo

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer)
    func cameraManager(_ manager: CameraManager, didChangeRunning isRunning: Bool)
    func cameraManager(_ manager: CameraManager, didFail error: Error)
}

final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "CameraManager.Queue")
    weak var delegate: CameraManagerDelegate?

    private var isConfigured = false

    override init() {
        super.init()
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                if !self.isConfigured {
                    try self.configureSession()
                    self.isConfigured = true
                }
                if !self.session.isRunning {
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.delegate?.cameraManager(self, didChangeRunning: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.cameraManager(self, didFail: error)
                }
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.delegate?.cameraManager(self, didChangeRunning: false)
                }
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        // Input (Back Wide Camera)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Back camera not available"])
        }

        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }

        // Output
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            throw NSError(domain: "CameraManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add video output"])
        }

        // Orientation
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.cameraManager(self, didOutput: pb)
    }
}
