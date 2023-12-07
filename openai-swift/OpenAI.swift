//
//  OpenAIChatAPI.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/9/23.
//

import Foundation


public class OpenAI {
    let baseURL: URL = URL(string: "https://api.openai.com/v1/")!
    let apiKey: String

    private lazy var session: URLSession = URLSession(configuration: .default, delegate: streamManager, delegateQueue: nil)
    private lazy var streamManager: StreamSessionManager = StreamSessionManager()

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func perform<Request: OpenAIRequest>(request: Request, completion: @escaping (Result<Request.Response, Error>) -> Void, didCompleteStreaming: ((Error?) -> Void)? = nil) {
        var httpRequest = prepareRequest(path: Request.path)
        do { httpRequest.httpBody = try JSONEncoder().encode(request) }
        catch { return completion(.failure(APIError.invalidData)) }
        if request.stream { streamManager.stream(task: session.dataTask(with: httpRequest), eventHandler: completion, didCompleteStream: didCompleteStreaming) }
        else { perform(request: httpRequest, completion: completion) }
    }

    private func perform<Response: Decodable>(request: URLRequest, completion: @escaping (Result<Response, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(APIError.requestFailed)) }
            guard httpResponse.statusCode == 200 else { return completion(.failure(APIError.responseUnsuccessful(statusCode: httpResponse.statusCode))) }
            guard let data = data else { return completion(.failure(APIError.invalidData)) }
            do { completion(.success(try JSONDecoder().decode(Response.self, from: data))) }
            catch { completion(.failure(APIError.jsonParsingFailure)) }
        }.resume()
    }

    private func prepareRequest(path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    class StreamSessionManager: NSObject, URLSessionDataDelegate {
        var didReceiveEvent: ((Data) -> Void)?
        var didCompleteStream: ((Error?) -> Void)?
        private var task: URLSessionDataTask?
        
        func stream<Response: Decodable>(task: URLSessionDataTask, eventHandler: @escaping (Result<Response, Error>) -> Void, didCompleteStream: ((Error?) -> Void)? = nil) {
            didReceiveEvent = { data in
                do { eventHandler(.success(try JSONDecoder().decode(Response.self, from: data))) }
                catch { eventHandler(.failure(error)) }
            }
            self.didCompleteStream = didCompleteStream
            self.task = task; task.resume()
        }
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let eventString = String(data: data, encoding: .utf8) else { return }
            let lines = eventString.split(separator: "\n")
            for line in lines where line.hasPrefix("data:") && line != "data: [DONE]" {
                if let data = String(line.dropFirst(5)).data(using: .utf8) { didReceiveEvent?(data) }
                else { task?.cancel(); task = nil; didReceiveEvent = nil; didCompleteStream = nil }
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            didCompleteStream?(error)
        }
    }
}

extension OpenAI {
    public func performChatCompletionRequest(messages: [Message], model: Model = .gpt35Turbo, stream: Bool = false, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void, didCompleteStreaming: @escaping (Error?) -> Void = {_ in}) {
        perform<ChatCompletion>(request: ChatCompletionRequest(model: model, messages: messages, stream: stream), completion: completion, didCompleteStreaming: didCompleteStreaming)
    }
}

public protocol OpenAIRequest: Encodable {
    associatedtype Response: Decodable
    static var path: String { get }
}

extension OpenAIRequest {
    var stream: Bool {
        if let chat = self as? OpenAI.ChatCompletionRequest {
            return chat.stream ?? false
        }
        return false
    }
}

public extension OpenAI {
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
        public static var cases: [Model] = [.gpt35Turbo, .gpt35Turbo0301, .gpt4]
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

        public init(model: Model, messages: [Message], temperature: Double? = nil, top_p: Double? = nil, n: Int? = nil, stream: Bool? = nil, stop: Stop? = nil, max_tokens: Int? = nil, presence_penalty: Double? = nil, frequency_penalty: Double? = nil, logit_bias: [String: Double]? = nil, user: String? = nil, response_type: ResponseType? = nil, seed: Int? = nil) {
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
        public let object: String
        public let created: Int
        public let choices: [Choice]
        public let usage: Usage?
        public let model: String?

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
