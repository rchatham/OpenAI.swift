//
//  OpenAI-SwiftTests.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 12/6/23.
//

import XCTest
@testable import OpenAI_Swift

class OpenAI_SwiftTests: XCTestCase {
    func getData(filename: String) throws -> Data? {
        return try Data.getData(filename: filename, bundle: Bundle(for: type(of: self)))
    }
}

extension Data {
    var string: String {
        return String(data: self, encoding: .utf8)!
    }
    var dictionary: [String: String]? {
        return (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)).flatMap { $0 as? [String: String] }
    }
    func asDictionary() throws -> [String: Any] {
        guard let dictionary = try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any] else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "failed to convert to dictionary"))
        }
        return dictionary
    }
    static func encode(_ encodable: Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(encodable)
    }
    static func getData(filename: String, bundle: Bundle) throws -> Data? {
        if let path = bundle.url(forResource: filename, withExtension: "json") {
            return try Data(contentsOf: path)
        }
        return nil
    }
}

class MockURLSession: URLSession {

}
