import Foundation
import CommonCrypto

actor HashCalculator {
    private let bufferSize = 1024 * 1024

    func calculateSHA256(for fileURL: URL) throws -> String? {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if data.isEmpty { return false }
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    CC_SHA256_Update(&context, baseAddress, CC_LONG(data.count))
                }
            }
            return true
        }) {}

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
