import ScreenCaptureKit
import CoreMedia
import CoreVideo
import IOSurface

enum CaptureEngineError: Error, LocalizedError {
    case permissionDenied
    case noDisplayAvailable
    case noWindowAvailable
    case streamCreationFailed
    case streamAlreadyRunning
    case streamNotRunning
    case invalidTarget
    case contentUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission has not been granted."
        case .noDisplayAvailable:
            return "No display is available for capture."
        case .noWindowAvailable:
            return "No window matching the requested ID was found."
        case .streamCreationFailed:
            return "Failed to create the capture stream."
        case .streamAlreadyRunning:
            return "A capture stream is already running."
        case .streamNotRunning:
            return "No capture stream is currently running."
        case .invalidTarget:
            return "The capture target is not valid."
        case .contentUnavailable:
            return "Unable to retrieve shareable content from the system."
        }
    }
}

enum CaptureTarget {
    case display(displayID: CGDirectDisplayID)
    case window(windowID: CGWindowID)
}

struct DisplayInfo: Identifiable {
    let displayID: CGDirectDisplayID
    let width: Int
    let height: Int
    let name: String

    var id: CGDirectDisplayID { displayID }
}

struct WindowInfo: Identifiable {
    let windowID: CGWindowID
    let name: String
    let ownerName: String
    let width: Int
    let height: Int

    var id: CGWindowID { windowID }
}

struct CaptureFrame {
    let pixelBuffer: CVPixelBuffer
    let ioSurface: IOSurface?
    let displayTime: CMTime
}

protocol CaptureEngineDelegate: AnyObject {
    func captureEngine(_ engine: CaptureEngine, didOutput frame: CaptureFrame)
    func captureEngine(_ engine: CaptureEngine, didEncounterError error: Error)
    func captureEngineDidStop(_ engine: CaptureEngine)
}

extension CaptureEngineDelegate {
    func captureEngine(_ engine: CaptureEngine, didEncounterError error: Error) {}
    func captureEngineDidStop(_ engine: CaptureEngine) {}
}

final class CaptureEngine: NSObject {

    private var stream: SCStream?
    private var streamConfiguration: SCStreamConfiguration?
    private var currentTarget: CaptureTarget?
    private let captureQueue = DispatchQueue(label: "com.jiaremote.capture.engine", qos: .userInteractive)

    private(set) var isRunning = false

    weak var delegate: CaptureEngineDelegate?

    deinit {
        stop()
    }

    static func checkPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        return CGRequestScreenCaptureAccess()
    }

    static func fetchDisplays() async throws -> [DisplayInfo] {
        let content = try await fetchShareableContent()
        return content.displays.map { display in
            DisplayInfo(
                displayID: display.displayID,
                width: Int(display.width),
                height: Int(display.height),
                name: "Display \(display.displayID)"
            )
        }
    }

    static func fetchWindows() async throws -> [WindowInfo] {
        let content = try await fetchShareableContent()
        return content.windows.compactMap { window in
            guard let name = window.title, !name.isEmpty else { return nil }
            guard let ownerName = window.owningApplication?.applicationName else { return nil }
            guard ownerName != "Window Server" else { return nil }
            return WindowInfo(
                windowID: window.windowID,
                name: name,
                ownerName: ownerName,
                width: Int(window.frame.width),
                height: Int(window.frame.height)
            )
        }
    }

    private static func fetchShareableContent() async throws -> SCShareableContent {
        do {
            return try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            JiaLog("[CaptureEngine] SCShareableContent failed: \(error)")
            throw CaptureEngineError.contentUnavailable
        }
    }

    func start(target: CaptureTarget) throws {
        guard !isRunning else {
            throw CaptureEngineError.streamAlreadyRunning
        }

        guard CaptureEngine.checkPermission() else {
            throw CaptureEngineError.permissionDenied
        }

        currentTarget = target
        let semaphore = DispatchSemaphore(value: 0)
        var setupError: Error?

        Task {
            do {
                let content = try await Self.fetchShareableContent()
                let filter: SCContentFilter

                switch target {
                case .display(let displayID):
                    guard let scDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
                        setupError = CaptureEngineError.noDisplayAvailable
                        semaphore.signal()
                        return
                    }
                    filter = SCContentFilter(display: scDisplay, excludingWindows: [])

                case .window(let windowID):
                    guard let scWindow = content.windows.first(where: { $0.windowID == windowID }) else {
                        setupError = CaptureEngineError.noWindowAvailable
                        semaphore.signal()
                        return
                    }
                    if #available(macOS 13.3, *) {
                        filter = SCContentFilter(desktopIndependentWindow: scWindow)
                    } else {
                        guard let scDisplay = content.displays.first(where: {
                            $0.displayID == CGMainDisplayID()
                        }) ?? content.displays.first else {
                            setupError = CaptureEngineError.noDisplayAvailable
                            semaphore.signal()
                            return
                        }
                        filter = SCContentFilter(display: scDisplay, including: [scWindow])
                    }
                }

                let config = Self.buildStreamConfiguration()

                let newStream = SCStream(filter: filter, configuration: config, delegate: self)
                try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)

                self.streamConfiguration = config
                self.stream = newStream

                semaphore.signal()
            } catch let error as CaptureEngineError {
                setupError = error
                semaphore.signal()
            } catch {
                setupError = error
                semaphore.signal()
            }
        }

        semaphore.wait()

        if let error = setupError {
            currentTarget = nil
            throw error
        }

        stream?.startCapture()
        isRunning = true
    }

    func stop() {
        guard isRunning, let stream else {
            return
        }

        isRunning = false

        stream.stopCapture()

        self.stream = nil
        streamConfiguration = nil
        currentTarget = nil
    }

    func updateConfiguration(configurator: (SCStreamConfiguration) -> Void) throws {
        guard let stream, let config = streamConfiguration else {
            throw CaptureEngineError.streamNotRunning
        }

        configurator(config)
        stream.updateConfiguration(config)
    }

    private static func buildStreamConfiguration() -> SCStreamConfiguration {
        let config = SCStreamConfiguration()

        config.showsCursor = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(1000))
        config.scalesToFit = false

        if #available(macOS 13.0, *) {
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.queueDepth = 3
        }

        if #available(macOS 14.0, *) {
            config.captureResolution = .automatic
        }

        return config
    }
}

extension CaptureEngine: SCStreamDelegate, SCStreamOutput {

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        isRunning = false
        self.stream = nil
        streamConfiguration = nil
        currentTarget = nil
        delegate?.captureEngine(self, didEncounterError: error)
        delegate?.captureEngineDidStop(self)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard isRunning else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ioSurface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue()
        let displayTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let frame = CaptureFrame(
            pixelBuffer: pixelBuffer,
            ioSurface: ioSurface,
            displayTime: displayTime
        )

        delegate?.captureEngine(self, didOutput: frame)
    }
}
