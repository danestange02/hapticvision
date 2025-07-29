# Changelog

## [Unreleased]
### Added
- Initial implementation of HapticVision: camera-to-haptic pipeline.
- SwiftUI interface with VoiceOver support.
- Adjustable scan speed (4–32 Hz) and grid resolution (8x8–64x64).

### Changed
- Optimized performance: grid caching, Accelerate for luminance, CADisplayLink for timing.
- Improved thread safety: NSLock for pixel buffer, engineQueue for haptics.
- Enhanced error handling: camera permissions, frame drops, render errors.
- Improved accessibility: VoiceOver for sliders, extended gridSize range (8–64).
- Added Xcode project and Swift Package for Playgrounds compatibility.

### Fixed
- Resolved potential crashes from unsynchronized pixel buffer access.
- Fixed redundant haptic engine starts and zero-intensity events.
- Addressed camera permission feedback in UI.
