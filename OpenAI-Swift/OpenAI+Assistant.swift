//
//  OpenAI+Assistant.swift
//  openai-swift
//
//  Created by Reid Chatham on 12/8/23.
//

import Foundation

public extension OpenAI {
    struct Assistant: Codable {
        var id: String
        var object: String
        var createdAt: Int
        var name: String
        var description: String?
        var model: String
        var instructions: String
        var tools: [Tool]
        var fileIds: [String]
        var metadata: [String: String]

        enum CodingKeys: String, CodingKey {
            case id
            case object
            case createdAt = "created_at"
            case name
            case description
            case model
            case instructions
            case tools
            case fileIds = "file_ids"
            case metadata
        }
    }

    enum Tool: Codable {
        case codeInterpreter
        case retrieval
        case function(FunctionSchema)

        public struct FunctionSchema: Codable {
            var name: String
            var description: String?
            var parameters: Parameters // JSON Schema object
            public init(name: String, description: String, parameters: Parameters = Parameters(properties: [:])) {
                self.name = name
                self.description = description
                self.parameters = parameters
            }

            public struct Parameters: Codable {
                var type: String = "object"
                var properties: [String:Property]
                var required: [String]?
                public init(properties: [String : Property] = [:], required: [String]? = nil) {
                    self.properties = properties
                    self.required = required
                }

                public struct Property: Codable {
                    var type: String
                    var enumValues: [String]?
                    var description: String?
                    public init(type: String, enumValues: [String]? = nil, description: String? = nil) {
                        self.type = type
                        self.enumValues = enumValues
                        self.description = description
                    }
                    enum CodingKeys: String, CodingKey {
                        case type, description
                        case enumValues = "enum"
                    }
                }
            }
        }

        enum CodingKeys: String, CodingKey {
            case type, function
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "code_interpreter": self = .codeInterpreter
            case "retrieval": self = .retrieval
            case "function": self = .function(try container.decode(FunctionSchema.self, forKey: .function))
            default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .codeInterpreter: try container.encode("code_interpreter", forKey: .type)
            case .retrieval: try container.encode("retrieval", forKey: .type)
            case .function(let functionDetails): try container.encode("function", forKey: .type)
                try container.encode(functionDetails, forKey: .function)
            }
        }
    }
}
