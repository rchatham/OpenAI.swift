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

    internal init(testURLSessionConfiguration: URLSessionConfiguration) {
        self.apiKey = ""
        session = URLSession(configuration: testURLSessionConfiguration, delegate: streamManager, delegateQueue: nil)
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
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(.requestFailed(error))) }
            guard httpResponse.statusCode == 200 else { return completion(.failure(.responseUnsuccessful(statusCode: httpResponse.statusCode))) }
            guard let data = data else { return completion(.failure(.invalidData)) }
            OpenAI.decode(completion: completion)(data)
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
        private var didReceiveEvent: ((Data) -> Void)?
        private var didCompleteStream: ((Error?) -> Void)?
        private var task: URLSessionDataTask?
        
        func stream<Response: Decodable>(task: URLSessionDataTask, eventHandler: @escaping (Result<Response, OpenAIError>) -> Void, didCompleteStream: ((Error?) -> Void)? = nil) {
            didReceiveEvent = decode(completion: eventHandler)
            self.didCompleteStream = { [unowned self] error in
                didCompleteStream?(error); (self.task, self.didReceiveEvent, self.didCompleteStream) = (nil, nil, nil)
            }
            self.task = task; task.resume()
        }
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            if let error = OpenAI.decodeError(data: data) { return didCompleteStream?(error) ?? () }
            guard let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") else { return }
            for line in lines where line.hasPrefix("data:") {
                guard line != "data: [DONE]" else { return }
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
        return (self as? OpenAI.ChatCompletionRequest)?.stream ?? false
    }
}

public enum OpenAIError: Error {
    case invalidData, streamParsingFailure, invalidURL
    case requestFailed(Error?)
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
    enum Model: String, Codable, CaseIterable {
        case gpt35Turbo = "gpt-3.5-turbo"
        case gpt35Turbo_0301 = "gpt-3.5-turbo-0301"
        case gpt35Turbo_1106 = "gpt-3.5-turbo-1106"
        case gpt35Turbo_16k = "gpt-3.5-turbo-16k"
        case gpt35Turbo_Instruct = "gpt-3.5-turbo-instruct"
        case gpt4 = "gpt-4"
        case gpt4_0613 = "gpt-4-0613"
        case gpt4Turbo_1106Preview = "gpt-4-1106-preview"
        case gpt4_VisionPreview = "gpt-4-vision-preview"
        case gpt4_32k = "gpt-4-32k"
        case gpt4_32k_0613 = "gpt-4-32k-0613"
    }
}

// Helpers
public extension OpenAI {
    static func decode<Response: Decodable>(completion: @escaping (Result<Response, OpenAIError>) -> Void) -> (Data) -> Void {
        return { completion(decode(data: $0)) }
    }

    static func decode<Response: Decodable>(data: Data) -> Result<Response, OpenAIError> {
        let d = JSONDecoder(); do { return .success(try d.decode(Response.self, from: data)) }
        catch { return .failure(decodeError(data: data, decoder: d) ?? .jsonParsingFailure(error)) }
    }

    static func decodeError(data: Data, decoder: JSONDecoder = JSONDecoder()) -> OpenAIError? {
        return (try? decoder.decode(OpenAIError.ErrorResponse.self, from: data)).flatMap { .apiError($0) }
    }
}
