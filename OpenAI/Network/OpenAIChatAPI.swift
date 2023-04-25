//
//  OpenAIChatAPI.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/9/23.
//

import Foundation
import CoreData

// Conversion functions for ChatCompletionRequest and ChatCompletionResponse models
extension ChatCompletionRequest.Message {
    func toCoreDataMessage(in context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.role = role.rawValue
        message.content = content
        message.createdAt = Date()
        message.id = UUID()
        return message
    }
}

extension ChatCompletionRequest.Message {
    func toDictionary() -> [String: Any] {
        return [
            "role": role.rawValue,
            "content": content
        ]
    }
}

extension ChatCompletionResponse.Choice.Message {
    func toCoreDataMessage(in context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.role = role.rawValue
        message.content = content
        message.createdAt = Date()
        message.id = UUID()
        return message
    }
}

enum APIError: Error {
    case requestFailed
    case invalidData
    case responseUnsuccessful(statusCode: Int)
    case jsonParsingFailure
    case invalidURL
}

enum Model: String, Codable {
    case gpt35Turbo = "gpt-3.5-turbo"
    case gpt35Turbo0301 = "gpt-3.5-turbo-0301"
    case gpt4 = "gpt-4"
}

extension Model {
    static var cases: [Model] = [
        .gpt35Turbo,
        .gpt35Turbo0301,
        .gpt4
    ]
}

enum Role: String, Codable {
    case system
    case user
    case assistant
}

struct ChatCompletionRequest: Codable {
    let model: Model
    let messages: [Message]
    let temperature: Double?
    let top_p: Double?
    let n: Int?
    let stream: Bool?
    let stop: Stop?
    let max_tokens: Int?
    let presence_penalty: Double?
    let frequency_penalty: Double?
    let logit_bias: [String: Double]?
    let user: String?

    init(model: Model, messages: [Message], temperature: Double? = nil, top_p: Double? = nil, n: Int? = nil, stream: Bool? = nil, stop: Stop? = nil, max_tokens: Int? = nil, presence_penalty: Double? = nil, frequency_penalty: Double? = nil, logit_bias: [String: Double]? = nil, user: String? = nil) {
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
    }

    struct Message: Codable {
        let role: Role
        let content: String
    }

    enum Stop: Codable {
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                throw DecodingError.typeMismatch(Stop.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for Stop"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let string):
                try container.encode(string)
            case .array(let array):
                try container.encode(array)
            }
        }
    }
}

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage?
    let model: String?

    struct Choice: Codable {
        let index: Int
        let message: Message?
        let finish_reason: String?
        let delta: Delta?

        struct Message: Codable {
            let role: Role
            let content: String
        }

        struct Delta: Codable {
            let role: Role?
            let content: String?
        }
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

class OpenAIChatAPI {
    let baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!
    let apiKey: String
    private let session: URLSession
    fileprivate let handler = ServerSentEventsHandler<ChatCompletionResponse>()

    init(apiKey: String) {
        self.apiKey = apiKey
        self.session = URLSession(configuration: .default)
    }

    func sendChatCompletionRequest(model: Model, messages: [ChatCompletionRequest.Message], stream: Bool = false, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void) {
        var request = prepareRequest()
        let requestBody = ChatCompletionRequest(model: model, messages: messages, stream: stream)
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return completion(.failure(APIError.invalidData))
        }

        if stream {
            handler.onEventReceived = completion
            handler.onComplete = {}
            handler.connect(with: request)
        } else {
            makeRequest(request: request, completion: completion)
        }
    }

    private func makeRequest(request: URLRequest, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void) {
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.requestFailed))
                return
            }

            if httpResponse.statusCode == 200 {
                guard let data = data else {
                    completion(.failure(APIError.invalidData))
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let chatCompletionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                    completion(.success(chatCompletionResponse))
                } catch {
                    completion(.failure(APIError.jsonParsingFailure))
                }
            } else {
                completion(.failure(APIError.responseUnsuccessful(statusCode: httpResponse.statusCode)))
            }
        }

        task.resume()
    }

    private func prepareRequest() -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }
}
