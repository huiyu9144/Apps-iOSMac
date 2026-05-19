import Foundation
import IOKit

final class TemperatureService {
    func readTemperature() -> Double? {
        let matchingDict = IOServiceMatching("AppleARMIODevice")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let properties = IORegistryEntryCreateCFProperty(service, "temperature" as CFString, kCFAllocatorDefault, 0) {
                let value = properties.takeRetainedValue() as? Double
                if value != nil {
                    return value
                }
            }

            if let properties = IORegistryEntryCreateCFProperty(service, "sensor-type" as CFString, kCFAllocatorDefault, 0) {
                let sensorType = properties.takeRetainedValue() as? String
                if sensorType == "die_temp" {
                    if let tempValue = IORegistryEntryCreateCFProperty(service, "sensor-value" as CFString, kCFAllocatorDefault, 0) {
                        let value = tempValue.takeRetainedValue() as? Double
                        if let v = value {
                            return v
                        }
                    }
                }
            }

            service = IOIteratorNext(iterator)
        }

        return readTemperatureViaSMC()
    }

    private func readTemperatureViaSMC() -> Double? {
        var conn: io_connect_t = 0
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))

        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        guard result == KERN_SUCCESS else { return nil }
        defer { IOServiceClose(conn) }

        let keys = ["TC0P", "TC0D", "TC0H"]
        for key in keys {
            if let temp = readSMCKey(conn: conn, key: key) {
                return temp
            }
        }

        return nil
    }

    private func readSMCKey(conn: io_connect_t, key: String) -> Double? {
        let inputSize = MemoryLayout<SMCParamStruct>.size
        var outputSize = MemoryLayout<SMCParamStruct>.size

        var input = SMCParamStruct()
        input.key = smcKeyToUInt32(key)
        input.data8 = SMC_CMD_READ_BYTES

        let inputPtr = UnsafeMutableRawPointer.allocate(byteCount: inputSize, alignment: MemoryLayout<UInt8>.alignment)
        defer { inputPtr.deallocate() }
        inputPtr.storeBytes(of: input, as: SMCParamStruct.self)

        var output = SMCParamStruct()

        let result = IOConnectCallStructMethod(conn, UInt32(KERNEL_INDEX_SMC), inputPtr, inputSize, &output, &outputSize)

        guard result == KERN_SUCCESS else { return nil }

        if output.result != SMC_KEY_RESULT_SUCCESS { return nil }

        let value = smcBytesToDouble(output.bytes, dataType: output.keyInfo.dataType)
        return value
    }

    private func smcKeyToUInt32(_ key: String) -> UInt32 {
        let chars = key.utf8
        var result: UInt32 = 0
        for (i, char) in chars.enumerated() {
            result |= UInt32(char) << (8 * (3 - i))
        }
        return result
    }

    private func smcBytesToDouble(_ bytes: SMCBytes, dataType: UInt32) -> Double? {
        let type = String(format: "%c%c%c%c",
                         (dataType >> 24) & 0xFF,
                         (dataType >> 16) & 0xFF,
                         (dataType >> 8) & 0xFF,
                         dataType & 0xFF)

        switch type {
        case "sp78":
            let intVal = Int16(bytes.0) << 8 | Int16(bytes.1)
            return Double(intVal) / 256.0
        case "flt ":
            let intVal = UInt32(bytes.0) << 24 | UInt32(bytes.1) << 16 | UInt32(bytes.2) << 8 | UInt32(bytes.3)
            return Double(Float(bitPattern: intVal))
        default:
            return nil
        }
    }
}

private let KERNEL_INDEX_SMC: UInt32 = 2
private let SMC_CMD_READ_BYTES: UInt8 = 5
private let SMC_KEY_RESULT_SUCCESS: UInt8 = 0

private struct SMCParamStruct {
    var key: UInt32 = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes = SMCBytes(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

private struct SMCKeyInfoData {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

private typealias SMCBytes = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)
