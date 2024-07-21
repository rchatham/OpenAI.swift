//
//  JSONSchema.swift
//  openai-swift
//
//  Created by Reid Chatham on 12/16/23.
//

import Foundation

let schema: JSONSchema = .object([
    "param1" : .boolean,
    "param2" : .integer
])

public indirect enum JSONSchema: Codable {
    case string, integer, boolean, object([String:JSONSchema], [String]? = nil), array(JSONSchema), null
    public var type: String {
        switch self {
        case .string: return "string"
        case .integer: return "integer"
        case .boolean: return "boolean"
        case .object: return "object"
        case .array: return "array"
        case .null: return "null"
        }
    }
    enum CodingKeys: CodingKey {
        case type, items, properties, required
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "string": self = .string
        case "integer": self = .integer
        case "boolean": self = .boolean
        case "object":
            let obj = try container.decode([String:JSONSchema].self, forKey: .properties)
            let req = try container.decodeIfPresent([String].self, forKey: .required)
            self = .object(obj,req)
        case "array":
            let array = try container.decode(JSONSchema.self, forKey: .items)
            self = .array(array)
        case "null": self = .null
        default: throw DecodingError.typeMismatch(JSONSchema.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for Stop"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if case .object(let obj, _) = self {
            var container = encoder.singleValueContainer()
            try container.encode(obj)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if case .array(let property) = self {
            try container.encode(property, forKey: .items)
        }
    }
}

