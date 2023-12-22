//
//  OpenAI+Assistant.swift
//  openai-swift
//
//  Created by Reid Chatham on 12/8/23.
//

import Foundation

public extension OpenAI {

//    enum Tool: Codable {
//        case codeInterpreter
//        case retrieval
//        case function(FunctionDetails)
//
//        public struct FunctionDetails: Codable {
//            var description: String?
//            var name: String
//            var parameters: [String: String] // JSON Schema object can be represented as [String: String]
//
//            init(description: String, name: String, parameters: [String : String]) {
//                self.description = description
//                self.name = name
//                self.parameters = parameters
//            }
//        }
//
//        enum CodingKeys: String, CodingKey {
//            case type
//            case function
//            case object
//        }
//
//        public init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            let type = try container.decode(String.self, forKey: .type)
//
//            switch type {
//            case "code_interpreter":
//                self = .codeInterpreter
//            case "retrieval":
//                self = .retrieval
//            case "function":
//                let functionDetails = try container.decode(FunctionDetails.self, forKey: .function)
//                self = .function(functionDetails)
//            default:
//                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
//            }
//        }
//
//        public func encode(to encoder: Encoder) throws {
//            var container = encoder.container(keyedBy: CodingKeys.self)
//
//            switch self {
//            case .codeInterpreter:
//                try container.encode("code_interpreter", forKey: .type)
//            case .retrieval:
//                try container.encode("retrieval", forKey: .type)
//            case .function(let functionDetails):
//                try container.encode("function", forKey: .type)
//                try container.encode(functionDetails, forKey: .function)
//            }
//        }
//    }

//    struct Assistant: Codable {
//        var id: String
//        var object: String
//        var createdAt: Int
//        var name: String
//        var description: String?
//        var model: String
//        var instructions: String
//        var tools: [Tool]
//        var fileIds: [String]
//        var metadata: [String: String]
//
//        enum CodingKeys: String, CodingKey {
//            case id
//            case object
//            case createdAt = "created_at"
//            case name
//            case description
//            case model
//            case instructions
//            case tools
//            case fileIds = "file_ids"
//            case metadata
//        }
//    }
}
