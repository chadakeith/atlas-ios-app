import SwiftUI
import VisionKit

/// Camera view that reads barcodes and printed text. Tapping a highlighted
/// item hands its string back through `onScan`.
struct SerialScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    /// False on the simulator and on devices without a Neural Engine.
    static var isSupported: Bool {
        DataScannerViewController.isSupported
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(), .text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let value = barcode.payloadStringValue {
                    onScan(value)
                }
            case .text(let text):
                onScan(text.transcript)
            @unknown default:
                break
            }
        }
    }
}

/// Full-screen scanning sheet with a typed fallback for the simulator or
/// hard-to-read labels.
struct ScanSerialSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onScan: (String) -> Void

    @State private var manualEntry = ""

    var body: some View {
        NavigationStack {
            Group {
                if SerialScannerView.isSupported {
                    SerialScannerView { value in
                        finish(with: value)
                    }
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        Text("Tap the serial number when it is highlighted")
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                            .padding(.top, 12)
                    }
                } else {
                    ContentUnavailableView(
                        "Camera scanning unavailable",
                        systemImage: "camera.metering.unknown",
                        description: Text("Live Text is not supported here. Type the serial number below.")
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Or type it", text: $manualEntry)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(submitManualEntry)
                    Button("Use", action: submitManualEntry)
                        .buttonStyle(.borderedProminent)
                        .disabled(SerialNumber.normalize(manualEntry).isEmpty)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("Scan serial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitManualEntry() {
        finish(with: manualEntry)
    }

    private func finish(with raw: String) {
        let serial = SerialNumber.normalize(raw)
        guard !serial.isEmpty else { return }
        onScan(serial)
        dismiss()
    }
}
