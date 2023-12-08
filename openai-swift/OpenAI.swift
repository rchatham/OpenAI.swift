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
