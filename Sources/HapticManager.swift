import Foundation
import CoreHaptics
import os

final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private let log = Logger(subsystem: "HapticVision", category: "Haptics")
    private let engineQueue = DispatchQueue(label: "HapticManager.EngineQueue")

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            log.error("Haptics not supported on this device.")
            return
        }
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.stoppedHandler = { [weak self] reason in
                self?.log.debug("Haptic engine stopped: \(reason.rawValue)")
            }
            engine?.resetHandler = { [weak self] in
                self?.log.debug("Haptic engine reset; restarting.")
                do {
                    try self?.engine?.start()
                } catch {
                    self?.log.error("Failed to restart engine: \(error.localizedDescription)")
                }
            }
            try engine?.start()
        } catch {
            log.error("Failed to create/start haptic engine: \(error.localizedDescription)")
        }
    }

    /// Plays an upward transient sweep, one transient per row.
    /// - Parameters:
    ///   - intensities: Array of 0..1 brightness, top to bottom.
    ///   - totalDuration: Total sweep duration in seconds.
    func playSweep(intensities: [Float], totalDuration: TimeInterval = 0.12) {
        engineQueue.async { [weak self] in
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = self?.engine else { return }
            let count = max(1, intensities.count)
            let dt = totalDuration / Double(count)

            var events: [CHHapticEvent] = []
            events.reserveCapacity(count)
            for i in 0..<count {
                let t = dt * Double(i)
                let intensity = max(0.0, min(1.0, Double(intensities[i])))
                if intensity > 0.0 {
                    let sharpness = 0.5 + 0.5 * intensity // Brighter = sharper
                    let params = [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness))
                    ]
                    let event = CHHapticEvent(eventType: .hapticTransient, parameters: params, relativeTime: t)
                    events.append(event)
                }
            }

            do {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                if !engine.isRunning {
                    try engine.start()
                }
                try player.start(atTime: 0)
            } catch {
                self?.log.error("Failed to play sweep: \(error.localizedDescription)")
            }
        }
        // TODO: Consider caching CHHapticPlayer for common grid sizes to improve performance.
    }
}
