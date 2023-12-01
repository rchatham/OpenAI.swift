//
//  OpenAIChatAPI.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/9/23.
//

import Foundation


class OpenAIChatAPI: NSObject, URLSessionDataDelegate {
    let baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!
    let apiKey: String

    var didReceiveEvent: ((Result<ChatCompletionResponse, Error>) -> Void)?
    var didCompleteStream: (() -> Void)?

    private lazy var session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var task: URLSessionDataTask?

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendChatCompletionRequest(model: Model, messages: [Message], stream: Bool = false, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void, didCompleteStreaming: @escaping () -> Void = {}) {
        var request = prepareRequest()
        let requestBody = ChatCompletionRequest(model: model, messages: messages, stream: stream)
        do { request.httpBody = try JSONEncoder().encode(requestBody) }
        catch { return completion(.failure(APIError.invalidData)) }
        if stream { self.stream(request: request, eventHandler: completion, didCompleteStream: didCompleteStreaming) }
        else { performRequest(request: request, completion: completion) }
    }

    private func performRequest(request: URLRequest, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(APIError.requestFailed)) }
            guard httpResponse.statusCode == 200 else { return completion(.failure(APIError.responseUnsuccessful(statusCode: httpResponse.statusCode))) }
            guard let data = data else { return completion(.failure(APIError.invalidData)) }
            do { completion(.success(try JSONDecoder().decode(ChatCompletionResponse.self, from: data))) }
            catch { completion(.failure(APIError.jsonParsingFailure)) }
        }.resume()
    }

    private func prepareRequest() -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    func stream(request: URLRequest, eventHandler: @escaping (Result<ChatCompletionResponse, Error>) -> Void, didCompleteStream: @escaping () -> Void = {}) {
        task = session.dataTask(with: request)
        didReceiveEvent = eventHandler
        self.didCompleteStream = didCompleteStream
        task?.resume()
    }

    func processEvent(_ eventData: Data) {
        do { didReceiveEvent?(.success(try JSONDecoder().decode(ChatCompletionResponse.self, from: eventData))) }
        catch { didReceiveEvent?(.failure(error)) }
    }

    func disconnect() {
        task?.cancel(); task = nil
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let eventString = String(data: data, encoding: .utf8) else { return }
        let lines = eventString.split(separator: "\n")
        for line in lines where line.hasPrefix("data:") && line != "data: [DONE]" {
            let e = String(line.dropFirst(5)).data(using: .utf8)
            e != nil ? processEvent(e!) : disconnect()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        error != nil ? didReceiveEvent?(.failure(error!)) : didCompleteStream?()
    }
}

extension OpenAIChatAPI {
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
        static var cases: [Model] = [.gpt35Turbo, .gpt35Turbo0301, .gpt4]
    }

    enum Role: String, Codable {
        case system, user, assistant
    }

    struct Message: Codable {
        let role: Role
        let content: String
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
}
