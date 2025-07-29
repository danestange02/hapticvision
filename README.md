# HapticVision

HapticVision is an iOS app that converts camera brightness into haptic feedback, designed for accessibility to help blind and low-vision users sense their environment. It uses the iPhone’s back camera to capture frames, downsamples them to a grid (8x8 to 64x64), extracts columns, and generates haptic sweeps (4–32 Hz) based on brightness.

## Features
- Real-time camera-to-haptic conversion.
- Adjustable scan speed (4–32 columns/sec) and grid resolution (8x8 to 64x64).
- VoiceOver support for full accessibility.
- MIT license for open-source collaboration.

## Requirements
- iOS 13.0+ (iPhone 8+ recommended).
- Xcode 14+ (for macOS builds).
- Swift Playgrounds 4+ (iPadOS 13+ for testing).
- Camera access permission.

## Installation
1. Clone the repo:
   ```bash
   git clone https://github.com/danestange02/hapticvision.git
   ```
2. **Xcode (macOS)**:
   - Open `HapticVision.xcodeproj`.
   - Ensure frameworks (`CoreHaptics`, `AVFoundation`, `CoreImage`, `Accelerate`, `QuartzCore`, `SwiftUI`, `Foundation`, `Combine`) are linked.
   - Build for iPhone 8+ simulator or device (iOS 13+).
3. **Swift Playgrounds (iPad)**:
   - Copy `Sources/` files and `Package.swift` into a new Playground.
   - Add `PlaygroundMain.swift` to run the app.
   - Run and grant camera permissions.
4. **TestFlight**:
   - Build in Xcode, archive, and upload to App Store Connect for TestFlight distribution.

## Usage
- Launch the app and grant camera permissions.
- Tap “Start Scanning” to begin capturing frames and generating haptics.
- Adjust sliders for scan speed (`Column Rate`) and grid size (`Grid Size`).
- Point the camera at bright (e.g., window) or dark objects; feel stronger haptics for brighter areas.
- Enable VoiceOver for accessible navigation.

## Development
- Built with Swift, SwiftUI, AVFoundation, Core Haptics, Core Image, and Accelerate.
- Optimized for performance (grid caching, Accelerate luminance) and thread safety (NSLock, engineQueue).
- See `CHANGELOG.md` for updates.

## License
MIT License. See `LICENSE` for details.

## Contributing
Fork the repo, create a branch, and submit a pull request. Test changes in Xcode or Playgrounds before submitting.
