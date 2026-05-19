import AppKit
import AVFoundation
import CoreMedia
import CoreVideo
import SwiftUI

final class ScrollingCapturer: NSObject {
    private var completion: ((NSImage?) -> Void)?
    private var screenRecording: AVCaptureScreenInput?
    private var captureSession: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var frames: [CGImage] = []
    private var isRecording = false
    private var stopPanel: NSPanel?

    private let captureQueue = DispatchQueue(label: "com.cleanshot.scrolling.capture")
    private let ciContext = CIContext()

    func capture(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        requestScreenRecordingPermission()
        showCaptureInstructions()
    }

    private func showCaptureInstructions() {
        guard NSScreen.main != nil else {
            completion?(nil)
            return
        }

        let alert = NSAlert()
        alert.messageText = "Scrolling Capture"
        alert.informativeText = "Position the content you want to capture, then click Start. Scroll through the content, then click Stop."
        alert.addButton(withTitle: "Start Capture")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            startRecordingAsync()
        } else {
            completion?(nil)
        }
    }

    private func startRecordingAsync() {
        captureQueue.async { [weak self] in
            self?.startRecording()
        }
    }

    private func startRecording() {
        guard let screen = NSScreen.main else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }

        let session = AVCaptureSession()

        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        guard let input = AVCaptureScreenInput(displayID: displayID) else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }

        input.cropRect = .zero
        input.minFrameDuration = CMTime(value: 1, timescale: 5)

        guard session.canAddInput(input) else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }
        session.addInput(input)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)

        guard session.canAddOutput(videoOutput) else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }
        session.addOutput(videoOutput)

        session.startRunning()

        guard session.isRunning else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }

        self.captureSession = session
        self.screenRecording = input
        self.output = videoOutput
        self.frames = []
        self.isRecording = true

        DispatchQueue.main.async { [weak self] in
            self?.showStopButton()
        }
    }

    private func showStopButton() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 90),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.title = ""
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.contentView = NSHostingView(rootView: StopCaptureView(stopHandler: { [weak self] in
            self?.stopRecording()
        }))
        panel.makeKeyAndOrderFront(nil)
        stopPanel = panel
    }

    private func stopRecording() {
        isRecording = false
        stopPanel?.orderOut(nil)
        stopPanel = nil

        captureQueue.async { [weak self] in
            guard let self else { return }

            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.screenRecording = nil
            self.output = nil

            Thread.sleep(forTimeInterval: 0.3)
            self.processFrames()
        }
    }

    private func processFrames() {
        guard !frames.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
            }
            return
        }

        let maxHeight = frames.reduce(0) { max($0, CGFloat($1.height)) }
        let totalWidth = frames.reduce(0) { $0 + CGFloat($1.width) }

        let combined = NSImage(size: NSSize(width: totalWidth, height: maxHeight))
        combined.lockFocus()

        var xOffset: CGFloat = 0
        for cgImage in frames {
            let image = NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
            image.draw(
                at: NSPoint(x: xOffset, y: 0),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )
            xOffset += CGFloat(cgImage.width)
        }

        combined.unlockFocus()

        DispatchQueue.main.async { [weak self] in
            self?.completion?(combined)
        }
    }

    private func requestScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() == false {
            CGRequestScreenCaptureAccess()
        }
    }
}

extension ScrollingCapturer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            frames.append(cgImage)
        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    }
}

struct StopCaptureView: View {
    let stopHandler: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Capturing scroll content...")
                .font(.headline)

            Button("Stop Capture") {
                stopHandler()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Button("") {
                stopHandler()
            }
            .keyboardShortcut(.cancelAction)
            .hidden()
        }
        .padding()
    }
}
