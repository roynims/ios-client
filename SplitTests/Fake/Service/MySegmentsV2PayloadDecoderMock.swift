//
//  MySegmentsV2PayloadDecoderMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//
@testable import Split

import Foundation

class MySegmentsV2PayloadDecoderMock: MySegmentsV2PayloadDecoder {

    var hashedKey: UInt64?
    var decodedString: String?
    var parsedKeyList: KeyList?
    var decodedBytes: Data?

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String {
        return decodedString ?? ""
    }

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        return decodedBytes ?? Data()
    }

    func hashKey(_ key: String) -> UInt64 {
        return hashedKey ?? 1
    }

    func parseKeyList(jsonString: String) -> KeyList? {
        return parsedKeyList
    }
}
