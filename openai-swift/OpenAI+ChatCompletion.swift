//
//  OpenAI+ChatCompletion.swift
//  openai-swift
//
//  Created by Reid Chatham on 12/7/23.
//

import Foundation


public extension OpenAI {
    func performChatCompletionRequest(messages: [Message], model: Model = .gpt35Turbo, stream: Bool = false, completion: @escaping (Result<OpenAI.ChatCompletionResponse, OpenAIError>) -> Void, didCompleteStreaming: ((Error?) -> Void)? = nil) {
        perform(request: OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream), completion: completion, didCompleteStreaming: didCompleteStreaming)
    }
}

public extension OpenAI {
    enum Role: String, Codable {
        case system, user, assistant
    }

    struct Message: Codable {
        public let role: Role
        public let content: String
        public init(role: Role, content: String) {
            self.role = role
            self.content = content
        }
    }

    struct ChatCompletionRequest: Codable, OpenAIRequest {
        public typealias Response = ChatCompletionResponse
        public static var path: String { "chat/completions" }
        let model: Model
        let messages: [Message]
        let temperature: Double?
        let top_p: Double?
        let n: Int? // how many chat completions to generate for each request
        let stream: Bool?
        let stop: Stop?
        let max_tokens: Int?
        let presence_penalty: Double?
        let frequency_penalty: Double?
        let logit_bias: [String: Double]?
        let user: String?
        let response_format: ResponseFormat?
        let seed: Int?
        let tools: [Tool]?
        let tool_choice: ToolChoice?

        public init(model: Model, messages: [Message], temperature: Double? = nil, top_p: Double? = nil, n: Int? = nil, stream: Bool? = nil, stop: Stop? = nil, max_tokens: Int? = nil, presence_penalty: Double? = nil, frequency_penalty: Double? = nil, logit_bias: [String: Double]? = nil, user: String? = nil, response_type: ResponseType? = nil, seed: Int? = nil, tools: [Tool]? = nil, tool_choice: ToolChoice? = nil) {
            self.model = model
            self.messages = messages
            self.temperature = temperature
            self.top_p = top_p
            self.n = n
            self.stream = stream
            self.stop = stop
            self.max_tokens = max_tokens
            self.presence_penalty = presence_penalty
            self.frequency_penalty = frequency_penalty
            self.logit_bias = logit_bias
            self.user = user
            self.response_format = response_type.flatMap { ResponseFormat(type: $0) }
            self.seed = seed
            self.tools = tools
            self.tool_choice = tool_choice
        }

        public enum Stop: Codable {
            case string(String)
            case array([String])

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) { self = .string(string) }
                else if let array = try? container.decode([String].self) { self = .array(array) }
                else { throw DecodingError.typeMismatch(Stop.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for Stop")) }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let string): try container.encode(string)
                case .array(let array): try container.encode(array)
                }
            }
        }

        public struct ResponseFormat: Codable {
            let type: ResponseType
            public init(type: ResponseType) {
                self.type = type
            }
        }

        public enum ResponseType: String, Codable {
            case text
            case json_object
        }

        public enum Tool: Codable {
            case function(FunctionDetails)

            public struct FunctionDetails: Codable {
                var description: String?
                var name: String
                var parameters: JSONSchema // JSON Schema object can be represented as [String: String]
                public init(description: String, name: String, parameters: JSONSchema) {
                    self.description = description
                    self.name = name
                    self.parameters = parameters
                }

                public struct JSONSchema: Codable {
                    var type: String = "object"
                    var properties: [String: String]
                    public init(properties: [String : String]) {
                        self.properties = properties
                    }
                }
            }

            enum CodingKeys: String, CodingKey {
                case type
                case function
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)

                switch type {
                case "function":
                    let functionDetails = try container.decode(FunctionDetails.self, forKey: .function)
                    self = .function(functionDetails)
                default:
                    throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .function(let functionDetails):
                    try container.encode("function", forKey: .type)
                    try container.encode(functionDetails, forKey: .function)
                }
            }
        }

        public enum ToolChoice: Codable {
            case none
            case auto
            case tool(ToolWrapper)

            public enum ToolWrapper: Codable {
                case function(String)

                public struct FunctionDetails: Codable {
                    var name: String
                    public init(name: String) { self.name = name }
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let type = try container.decode(String.self, forKey: .type)

                    switch type {
                    case "function":
                        let functionDetails = try container.decode(FunctionDetails.self, forKey: .function)
                        self = .function(functionDetails.name)
                    default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                    case .function(let name):
                        try container.encode("function", forKey: .type)
                        try container.encode(FunctionDetails(name: name), forKey: .function)
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case type
                    case function
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    switch stringValue {
                    case "none": self = .none
                    case "auto": self = .auto
                    default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string value")
                    }
                } else {
                    let toolWrapper = try ToolWrapper(from: decoder)
                    self = .tool(toolWrapper)
                }
            }

            public func encode(to encoder: Encoder) throws {
                switch self {
                case .none:
                    var container = encoder.singleValueContainer()
                    try container.encode("none")
                case .auto:
                    var container = encoder.singleValueContainer()
                    try container.encode("auto")
                case .tool(let toolWrapper):
                    try toolWrapper.encode(to: encoder)
                }
            }
        }
    }

    struct ChatCompletionResponse: Codable {
        public let id: String
        public let object: String
        public let created: Int
        public let choices: [Choice]
        public let usage: Usage?
        public let model: String?
        public let system_fingerprint: String?

        public struct Choice: Codable {
            public let index: Int
            public let message: Message?
            public let finish_reason: String?
            public let delta: Delta?

            public struct Delta: Codable {
                public let role: Role?
                public let content: String?
            }
        }

        public struct Usage: Codable {
            public let prompt_tokens: Int
            public let completion_tokens: Int
            public let total_tokens: Int
        }
    }
}
