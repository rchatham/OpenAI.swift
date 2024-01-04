//
//  Utilities.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 1/1/24.
//

import Foundation


extension Data {
    var string: String {
        return String(data: self, encoding: .utf8)!
    }
    var dictionary: [String: String]? {
        return (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)).flatMap { $0 as? [String: String] }
    }
    static func getData(filename: String, bundle: Bundle, fileExtension: String = "json") throws -> Data? {
        if let path = bundle.url(forResource: filename, withExtension: fileExtension) {
            return try Data(contentsOf: path)
        }
        return nil
    }
    init(_ encodable: Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self = try encoder.encode(encodable)
    }
}

extension Encodable {
    func data(outputFormatting: JSONEncoder.OutputFormatting = [] /*[.prettyPrinted, .sortedKeys]*/) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        return try encoder.encode(self)
    }
}
