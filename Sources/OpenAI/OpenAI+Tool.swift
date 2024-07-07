import Foundation


public extension OpenAI {
    enum Tool: Codable {
        case function(FunctionSchema)

        var name: String {
            switch self {
            case .function(let schema): return schema.name
            }
        }

        var description: String? {
            switch self {
            case .function(let schema): return schema.description
            }
        }

        public struct FunctionSchema: Codable {
            var name: String
            var description: String?
            var parameters: Parameters // JSON Schema object
            internal var callback: (([String:Any]) -> String?)? = nil
            public init(name: String, description: String, parameters: Parameters = Parameters(properties: [:]), callback: (([String:Any]) -> String?)? = nil) {
                self.name = name
                self.description = description
                self.parameters = parameters
                self.callback = callback
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                name = try container.decode(String.self, forKey: .name)
                description = try container.decodeIfPresent(String.self, forKey: .description)
                parameters = try container.decode(Parameters.self, forKey: .parameters)
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
                try container.encode(description, forKey: .description)
                try container.encode(parameters, forKey: .parameters)
            }

            enum CodingKeys: String, CodingKey {
                case name, description, parameters
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
}
