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
    
    public func perform<Request: OpenAIRequest>(request: Request, completion: @escaping (Result<Request.Response, OpenAIError>) -> Void, didCompleteStreaming: ((Error?) -> Void)? = nil) {
        var httpRequest = prepareRequest(path: Request.path)
        do { httpRequest.httpBody = try JSONEncoder().encode(request) }
        catch { return completion(.failure(.invalidData)) }
        if request.stream { streamManager.stream(task: session.dataTask(with: httpRequest), eventHandler: completion, didCompleteStream: didCompleteStreaming) }
        else { perform(request: httpRequest, completion: completion) }
    }

    private func perform<Response: Decodable>(request: URLRequest, completion: @escaping (Result<Response, OpenAIError>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(.requestFailed)) }
            guard httpResponse.statusCode == 200 else { return completion(.failure(.responseUnsuccessful(statusCode: httpResponse.statusCode))) }
            guard let data = data else { return completion(.failure(.invalidData)) }
            decode(completion: completion)(data)
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
        
        func stream<Response: Decodable>(task: URLSessionDataTask, eventHandler: @escaping (Result<Response, OpenAIError>) -> Void, didCompleteStream: ((Error?) -> Void)? = nil) {
            didReceiveEvent = decode(completion: eventHandler)
            self.didCompleteStream = { [unowned self] error in
                self.task?.cancel(); (self.task, self.didReceiveEvent, self.didCompleteStream) = (nil, nil, nil)
                didCompleteStream?(error)
            }
            self.task = task; task.resume()
        }
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let eventString = String(data: data, encoding: .utf8) else { return }
            let lines = eventString.split(separator: "\n")
            for line in lines where line.hasPrefix("data:") {
                guard line != "data: [DONE]" else { return didCompleteStream?(nil) ?? () }
                didReceiveEvent?(Data(String(line.dropFirst(5)).utf8))
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            didCompleteStream?(error)
        }
    }
}

public protocol OpenAIRequest: Encodable {
    associatedtype Response: Decodable
    static var path: String { get }
}

extension OpenAIRequest {
    var stream: Bool {
        if let chat = self as? OpenAI.ChatCompletionRequest { return chat.stream ?? false }
        return false
    }
}

public enum OpenAIError: Error {
    case requestFailed, invalidData, streamParsingFailure, invalidURL
    case jsonParsingFailure(Error)
    case responseUnsuccessful(statusCode: Int)
    case apiError(ErrorResponse)

    public struct ErrorResponse: Error, Codable {
        public let error: APIError
    }

    public struct APIError: Error, Codable {
        public let message: String
        public let type: String
        public let param: String?
        public let code: String?
    }
}

public extension OpenAI {
    enum Model: String, Codable {
        case gpt35Turbo = "gpt-3.5-turbo"
        case gpt35Turbo0301 = "gpt-3.5-turbo-0301"
        case gpt4 = "gpt-4"
        public static var cases: [Model] = [.gpt35Turbo, .gpt35Turbo0301, .gpt4]
    }
}

// Helpers

private func decode<Response: Decodable>(completion: @escaping (Result<Response, OpenAIError>) -> Void) -> (Data) -> Void {
    return { data in
        let d = JSONDecoder()
        do { completion(.success(try d.decode(Response.self, from: data))) }
        catch {
            let apiError = try? d.decode(OpenAIError.ErrorResponse.self, from: data)
            completion(.failure(apiError != nil ? .apiError(apiError!) : .jsonParsingFailure(error)))
        }
    }
}
