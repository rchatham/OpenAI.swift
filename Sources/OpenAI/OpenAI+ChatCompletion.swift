//
//  OpenAI+ChatCompletion.swift
//  openai-swift
//
//  Created by Reid Chatham on 12/7/23.
//

import Foundation

// TODO:
//   - add logprobs, top_logprobs
public extension OpenAI {
    func performChatCompletionRequest(messages: [Message], model: Model = .gpt35Turbo, stream: Bool = false, completion: @escaping (Result<OpenAI.ChatCompletionResponse, Error>) -> Void, didCompleteStreaming: ((Error?) -> Void)? = nil) {
        perform(request: OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream), completion: completion, didCompleteStreaming: didCompleteStreaming)
    }
}

public extension OpenAI {
    struct Message: Codable, CustomStringConvertible {
        public let role: Role
        public let content: Content
        public let name: String?
        public let tool_calls: [ToolCall]?
        public let tool_call_id: String?

        public var description: String {
            let tools: String? = tool_calls?.reduce("") {
                let name = $1.function.name ?? ""
                return $0.isEmpty ? (name) : ($0 + "," + name)
            }
            return """
                message info:
                  role: \(role)
                  content: \(content)
                  name: \(name ?? "")
                  tool_calls: \(tools ?? "")
                  tool_call_id: \(tool_call_id ?? "")
                """
        }
        
        public init(role: Role, content: String) {
            self.role = role
            self.content = .string(content)
            self.name = nil
            self.tool_calls = nil
            self.tool_call_id = nil
        }
        
        public init(role: Role, content: Content, name: String? = nil, tool_calls: [ToolCall]? = nil, tool_call_id: String? = nil) throws {
            switch role {
            case .user: if case .null = content { throw MessageError.missingContent }
            case .tool: guard tool_call_id != nil else { throw MessageError.missingContent }; fallthrough
            case .system, .assistant: guard content.description == "null" || content.description.hasPrefix("string: ") else { throw MessageError.invalidContent }
            }
            
            if role != .assistant, let tool_calls = tool_calls {
                print("\(role.rawValue.capitalized) is not able to use tool calls: \(tool_calls.description). Please check your configuration, only assistant messages are allowed to contain tool calls")
            }
            if role != .tool, let tool_call_id = tool_call_id {
                print("\(role.rawValue.capitalized) can not have tool_call_id: \(tool_call_id). Please check your configuration, only tool meesages may have a tool_call_id.")
            }
            
            self.role = role
            self.content = content
            self.name = name
            self.tool_calls = role == .assistant ? tool_calls : nil
            self.tool_call_id = role == .tool ? tool_call_id : nil
        }
        
        public enum Role: String, Codable {
            case system, user, assistant, tool
        }
        
        public enum Content: Codable, CustomStringConvertible {
            case null
            case string(String)
            case array([ContentType])

            public var description: String {
                switch self {
                case .null: return "null"
                case .string(let str): return "string: \(str)"
                case .array(let arr): return "array: \(arr)"
                }
            }

            public enum ContentType: Codable, CustomStringConvertible {
                case text(TextContent)
                case image(ImageContent)

                public var description: String {
                    switch self {
                    case .text(let txt): return "text: \(txt.text)"
                    case .image(let img): return "image: \(img.image_url)"
                    }
                }
                
                public var type: String {
                    switch self {
                    case .image(let img): return img.type
                    case .text(let txt): return txt.type
                    }
                }
                
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    if let text = try? container.decode(TextContent.self) { self = .text(text) }
                    else if let img = try? container.decode(ImageContent.self) { self = .image(img) }
                    else { throw DecodingError.typeMismatch(ContentType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type")) }
                }
            }
            
            public struct TextContent: Codable {
                var type: String = "text"
                public let text: String
                public init(text: String) {
                    self.text = text
                }
            }

            public struct ImageContent: Codable {
                var type: String = "image"
                public let image_url: ImageURL
                public init(image_url: ImageURL) {
                    self.image_url = image_url
                }
                
                public struct ImageURL: Codable {
                    public let url: String
                    public let detail: Detail?
                    public init(url: String, detail: Detail?) {
                        self.url = url
                        self.detail = detail
                    }
                }
                public enum Detail: String, Codable {
                    case auto, high, low
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) { self = .string(str) }
                else if let arr = try? container.decode([ContentType].self) { self = .array(arr) }
                else if container.decodeNil() { self = .null }
                else { throw DecodingError.typeMismatch(Content.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type")) }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let txt): try container.encode(txt)
                case .array(let array): try container.encode(array)
                case .null: try container.encodeNil()
                }
            }
        }

        public struct ToolCall: Codable, CustomStringConvertible {
            public let index: Int?
            public let id: String?
            public let type: ToolType?
            public let function: Function

            public var description: String {
                return """
                tool call:
                  index:    \(index != nil ? "\(index!)" : "no index")
                  id:       \(id ?? "no idea")
                  type:     \(type?.rawValue ?? "no type")
                  function: \(function.name ?? "name missing"): \(function.arguments)
                """
            }
            public init(index: Int, id: String, type: ToolType, function: Function) {
                self.index = index
                self.id = id
                self.type = type
                self.function = function
            }
            
            public enum ToolType: String, Codable {
                case function
            }
            
            public struct Function: Codable {
                public let name: String?
                public let arguments: String
                public init(name: String, arguments: String) {
                    self.name = name
                    self.arguments = arguments
                }
            }
        }
        
        public struct Delta: Codable {
            public let role: Role?
            public let content: String?
            public let tool_calls: [ToolCall]?
        }
    }
    
    enum MessageError: Error {
        case invalidRole
        case missingContent
        case invalidContent
    }

    struct ChatCompletionRequest: Codable, OpenAIRequest, StreamableRequest {
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

        public enum Tool: Codable {
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
                case "function":
                    let schema = try container.decode(FunctionSchema.self, forKey: .function)
                    self = .function(schema)
                default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
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
            case none, auto
            case tool(ToolWrapper)

            public enum ToolWrapper: Codable {
                case function(String)

                public struct FunctionDetails: Codable {
                    var name: String
                    public init(name: String) { self.name = name }
                }

                enum CodingKeys: String, CodingKey {
                    case type, function
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
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    switch stringValue {
                    case "none": self = .none
                    case "auto": self = .auto
                    default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string value")
                    }
                } else { self = .tool(try ToolWrapper(from: decoder)) }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .none: try container.encode("none")
                case .auto: try container.encode("auto")
                case .tool(let toolWrapper): try container.encode(toolWrapper)
                }
            }
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
    }

    struct ChatCompletionResponse: Codable {
        public let id: String
        public let object: String // chat.completion or chat.completion.chunk
        public let created: Int
        public let model: String? // TODO: make response return typed model response
        public let system_fingerprint: String?
        public let choices: [Choice]
        public let usage: Usage?

        public struct Choice: Codable {
            public let index: Int
            public let message: Message?
            public let finish_reason: FinishReason?
            public let delta: Message.Delta?
            
            public enum FinishReason: String, Codable {
                case stop, length, content_filter, tool_calls
            }
        }

        public struct Usage: Codable {
            public let prompt_tokens: Int
            public let completion_tokens: Int
            public let total_tokens: Int
        }
    }
}
