import Cocoa
import Vision

actor OCRService {
    static let shared = OCRService()

    private init() {}

    func recognizeText(in image: NSImage, languages: [String] = ["zh-Hans", "en-US"]) async -> Result<String, OCRServiceError> {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .failure(.invalidImage)
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(returning: .failure(.recognitionFailed(error.localizedDescription)))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: .failure(.noTextFound))
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                let result = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: .success(result))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = languages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: .failure(.recognitionFailed(error.localizedDescription)))
            }
        }
    }
}

enum OCRServiceError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image"
        case .noTextFound: return "No text found in image"
        case .recognitionFailed(let message): return "Recognition failed: \(message)"
        }
    }
}
