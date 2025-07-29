import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var vm = HapticVisionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("HapticVision")
                .font(.largeTitle)
                .bold()
                .accessibilityLabel("Haptic Vision")
                .accessibilityHint("Converts camera brightness into haptic sweeps.")

            Text(vm.statusText)
                .font(.callout)
                .accessibilityLabel("Status: " + vm.statusText)

            HStack {
                Button(action: {
                    if vm.isRunning {
                        vm.stop()
                    } else {
                        vm.start()
                    }
                }) {
                    Text(vm.isRunning ? "Stop Scanning" : "Start Scanning")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(vm.isRunning ? "Stop scanning" : "Start scanning")
                .accessibilityHint("Toggles camera capture and haptic output.")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Column Rate: \(String(format: "%.0f", vm.columnsPerSecond)) cols/sec")
                    .accessibilityLabel("Column rate \(Int(vm.columnsPerSecond)) columns per second")
                Slider(value: $vm.columnsPerSecond, in: 4...32, step: 1) {
                    Text("Columns per second")
                }
                .accessibilityHint("Adjust how fast columns are scanned and played as haptics.")
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Grid Size: \(vm.gridSize)x\(vm.gridSize)")
                    .accessibilityLabel("Grid size \(vm.gridSize) by \(vm.gridSize)")
                Slider(value: Binding(get: {
                    Double(vm.gridSize)
                }, set: { newVal in
                    vm.gridSize = Int(newVal)
                }), in: 8...48, step: 8) {
                    Text("Grid Size")
                }
                .accessibilityHint("Downsample camera to this square grid.")
            }
            .padding(.horizontal)

            Spacer()

            Text("Tip: Point camera at a bright window. You should feel stronger sweeps.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .onAppear {
            // Request camera permission early for VoiceOver flow
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
    }
}

#Preview {
    ContentView()
}
