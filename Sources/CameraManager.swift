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

    func checkPermissions(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    func start(preset: AVCaptureSession.Preset = .cif352x288) {
        checkPermissions { [weak self] granted in
            guard let self else { return }
            guard granted else {
                let error = NSError(domain: "CameraManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Camera access denied"])
                DispatchQueue.main.async {
                    self.delegate?.cameraManager(self, didFail: error)
                }
                return
            }
            queue.async {
                do {
                    if !self.isConfigured {
                        try self.configureSession(preset: preset)
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

    private func configureSession(preset: AVCaptureSession.Preset) throws {
        session.beginConfiguration()
        session.sessionPreset = preset

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Back camera not available"])
        }

        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            throw NSError(domain: "CameraManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add video output"])
        }

        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            let error = NSError(domain: "CameraManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to get pixel buffer"])
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.cameraManager(self!, didFail: error)
            }
            return
        }
        delegate?.cameraManager(self, didOutput: pb)
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let reason = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_DroppedFrameReason, attachmentModeOut: nil) as? String
        let error = NSError(domain: "CameraManager", code: -6, userInfo: [NSLocalizedDescriptionKey: "Dropped frame: \(reason ?? "Unknown")"])
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.cameraManager(self!, didFail: error)
        }
    }
}
