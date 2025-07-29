# HapticVision (Compile-Ready Source)

**What it does:**
HapticVision is an experimental iOS application that leverages your iPhone's camera to translate visual brightness into real-time haptic feedback. It continuously captures frames from the back camera, downsamples them into an N×N grid (default 32×32), and scans columns from left-to-right. Each column then generates an upward haptic sweep (from the top to the bottom of the column). Brighter areas in the image produce stronger and sharper taps, allowing you to "feel" the light patterns of your environment. You can adjust the haptic scan speed and grid resolution via on-screen sliders.

**Target:** iPhone running iOS 17+ (Core Haptics required).
**Accessibility:** All on-screen controls are fully labeled for VoiceOver, ensuring an accessible experience for blind and low-vision users.

## Quick Setup in Xcode (2–3 minutes)

1.  **Create New Project:**
    * Open Xcode → File → New → Project → iOS → App.
    * Set the project details:
        * **Product Name:** `HapticVision`
        * **Interface:** SwiftUI
        * **Language:** Swift
    * For faster compilation during initial setup, you can uncheck "Include Tests."

2.  **Replace Core Files:**
    * In the Xcode Project Navigator (left sidebar), locate and delete the auto-generated `ContentView.swift` and `YourAppNameApp.swift` files. Confirm you want to "Move to Trash" when prompted.
    * Drag the following files from this repository into your Xcode project's main group (ensure "Copy items if needed" is checked):
        * `HapticVisionApp.swift`
        * `ContentView.swift`
        * `CameraManager.swift`
        * `VisionProcessor.swift`
        * `HapticManager.swift`
        * `HapticVisionViewModel.swift`

3.  **Add Camera Usage Description:**
    * In the Xcode Project Navigator, click on your project's root folder (e.g., `HapticVision`).
    * Select the "Info" tab.
    * Click the `+` button next to any existing row to add a new key.
    * Type or select `Privacy - Camera Usage Description` (or `NSCameraUsageDescription` if typing directly).
    * In the "Value" column for this new key, enter a user-facing message, e.g.:
        `"HapticVision needs camera access to detect brightness for haptic feedback."`

4.  **Set Deployment Target:**
    * In the project **General** settings (still within your project's main settings), find **Deployment Info** and set the **Deployment Target** to `iOS 17.0` or later.

5.  **Run on Device:**
    * Connect your iPhone (iPhone 8 or newer required for Core Haptics) to your Mac via USB.
    * In Xcode, select your connected iPhone as the run destination from the scheme dropdown at the top.
    * Click the **Run** button (the solid triangle icon) or press `Cmd + R`. Xcode will build and install the app on your iPhone.
    * The first time you run, your iPhone will prompt you to grant camera access.

## Using the App

-   **Start/Stop:** Tap the “Start Scanning” button to activate the camera and begin haptic feedback. Tap again to stop.
-   **Experiment:** Point the camera at various light sources (windows, lamps) or contrasting objects (dark object on a light wall) and feel the difference in haptic intensity and sharpness as the sweep crosses them.
-   **Scan Speed:** Use the "Column Rate" slider to adjust how quickly the haptic sweeps occur (columns per second).
-   **Grid Resolution:** Use the "Grid Size" slider to change the resolution of the downsampled image, affecting the detail of the haptic feedback (adjustable between 8 and 64, in steps).

## Notes

-   **Haptic Compatibility:** Core Haptics is primarily designed for iPhone models (iPhone 8 and newer) with a Taptic Engine. While the app might run on iPads or in the Simulator, full haptic output will only occur on compatible iPhone hardware.
-   **Audio Fallback:** If you're interested in an **audio fallback** (e.g., sine tones) for devices without Core Haptics or for complementary feedback, please open an issue on GitHub, and we can explore integrating an `AVAudioEngine`-based `AudioManager` to mirror the haptic sweep.
-   **Design Philosophy:** This source code is intentionally kept simple and robust to maximize readability, maintainability, and extensibility, serving as a strong foundation for future enhancements in accessible sensory technology.
-   **AI-Assisted Development:** This project was developed with significant assistance from AI (e.g., ChatGPT/Gemini) for code generation and architectural guidance.
