import Cocoa

class CaptureService: NSObject {
    static let shared = CaptureService()

    private override init() {}

    func startCapture() {
        CaptureOverlayController.shared.startCapture()
    }

    func cancelCapture() {
        CaptureOverlayController.shared.cancelCapture()
    }
}
