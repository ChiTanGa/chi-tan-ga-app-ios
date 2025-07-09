import Foundation
import SwiftCBOR

enum ADCResolution: Int {
    case _12bit = 12
    case _24bit = 24
}

enum ADCCompression: Int {
    case _2x12bit_into_3bytes = 2123
    case _1x24bit_into_3bytes = 1243
}

struct ADSSensorData {
    let resolution: ADCResolution
    let compression: ADCCompression
    let time: UInt64
    let binaryData: [UInt8]
    let decodedReadingNumbers: [UInt32]

    init(fromCBOR data: Data) throws {
        guard let cbor = try CBOR.decode([UInt8](data)) else {
            throw NSError(domain: "ADSSensorData", code: 1, userInfo: [NSLocalizedDescriptionKey: "CBOR decoding failed"])
        }
        guard case let CBOR.map(map) = cbor else {
            throw NSError(domain: "ADSSensorData", code: 2, userInfo: [NSLocalizedDescriptionKey: "CBOR is not a map"])
        }

        func resValue(forKey key: String) -> ADCResolution? {
            guard let value = map[CBOR.utf8String(key)] else { return nil }
            switch value {
            case .unsignedInt(let v) where v == 12: return ._12bit
            case .unsignedInt(let v) where v == 24: return ._24bit
            default: return nil
            }
        }
        func compressionValue(forKey key: String) -> ADCCompression? {
            guard let value = map[CBOR.utf8String(key)] else { return nil }
            switch value {
            case .unsignedInt(let v) where v == 2123: return ._2x12bit_into_3bytes
            case .unsignedInt(let v) where v == 1243: return ._1x24bit_into_3bytes
            default: return nil
            }
        }
        func intValue(forKey key: String) -> Int? {
            guard let value = map[CBOR.utf8String(key)] else { return nil }
            switch value {
            case .unsignedInt(let v): return Int(v)
            case .negativeInt(let v): return -1 - Int(v)
            default: return nil
            }
        }
        func uIntValue(forKey key: String) -> UInt64? {
            guard let value = map[CBOR.utf8String(key)] else { return nil }
            if case .unsignedInt(let v) = value { return v }
            return nil
        }
        func byteStringValue(forKey key: String) -> [UInt8]? {
            guard let value = map[CBOR.utf8String(key)] else { return nil }
            if case .byteString(let v) = value { return v }
            return nil
        }

        guard
            let res = resValue(forKey: "res"),
            let cmp = compressionValue(forKey: "cmp"),
            let t = uIntValue(forKey: "t"),
            let bin = byteStringValue(forKey: "bin")
        else {
            throw NSError(domain: "ADSSensorData", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid CBOR fields"])
        }
        self.resolution = res
        self.compression = cmp
        self.time = t
        self.binaryData = bin
        self.decodedReadingNumbers = Self.unpackData(bin: bin, compression: cmp)
    }
    
    private static func unpackData(bin: [UInt8], compression: ADCCompression) -> [UInt32] {
        switch compression {
        case ._2x12bit_into_3bytes:
            return unpack12BitValues(bin)
        case ._1x24bit_into_3bytes:
            return unpack24BitValues(bin)
        }
    }
    
    private static func unpack12BitValues(_ bin: [UInt8]) -> [UInt32] {
        var result: [UInt32] = []
        var i = 0
        while i + 2 < bin.count {
            let byte0 = UInt16(bin[i])
            let byte1 = UInt16(bin[i + 1])
            let byte2 = UInt16(bin[i + 2])
            let value1 = (byte0 << 4) | (byte1 >> 4)
            let value2 = ((byte1 & 0x0F) << 8) | byte2
            result.append(UInt32(value1))
            result.append(UInt32(value2))
            i += 3
        }
        return result
    }

    private static func unpack24BitValues(_ bin: [UInt8]) -> [UInt32] {
        var result: [UInt32] = []
        var i = 0
        while i + 2 < bin.count {
            let value = (UInt32(bin[i]) << 16) | (UInt32(bin[i + 1]) << 8) | UInt32(bin[i + 2])
            result.append(value)
            i += 3
        }
        return result
    }
}
