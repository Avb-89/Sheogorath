//
//  GGUFReader.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct GGUFHeader: Sendable {
    let version: UInt32
    let tensorCount: UInt64
    let metadataCount: UInt64
}

enum GGUFReader {
    static func readHeader(from url: URL) throws -> GGUFHeader {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        guard let data = try handle.read(upToCount: 24), data.count == 24 else {
            throw GGUFError.invalidHeader
        }

        let bytes = [UInt8](data)

        guard bytes[0] == 0x47,
              bytes[1] == 0x47,
              bytes[2] == 0x55,
              bytes[3] == 0x46 else {
            throw GGUFError.invalidMagic
        }

        let version = readUInt32(bytes, at: 4)
        let tensorCount = readUInt64(bytes, at: 8)
        let metadataCount = readUInt64(bytes, at: 16)

        return GGUFHeader(
            version: version,
            tensorCount: tensorCount,
            metadataCount: metadataCount
        )
    }

    private static func readUInt32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        UInt32(bytes[offset]) |
        UInt32(bytes[offset + 1]) << 8 |
        UInt32(bytes[offset + 2]) << 16 |
        UInt32(bytes[offset + 3]) << 24
    }

    private static func readUInt64(_ bytes: [UInt8], at offset: Int) -> UInt64 {
        UInt64(bytes[offset]) |
        UInt64(bytes[offset + 1]) << 8 |
        UInt64(bytes[offset + 2]) << 16 |
        UInt64(bytes[offset + 3]) << 24 |
        UInt64(bytes[offset + 4]) << 32 |
        UInt64(bytes[offset + 5]) << 40 |
        UInt64(bytes[offset + 6]) << 48 |
        UInt64(bytes[offset + 7]) << 56
    }

    enum GGUFError: Error {
        case invalidHeader
        case invalidMagic
    }
}
