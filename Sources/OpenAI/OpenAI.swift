//
//  OpenAI.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/9/23.
//

import Foundation


// TODO:
//  - Use async/await/actor
//  - Pass closures to functions api
//  - Optionally call OpenAI api for functions without returning intermediate messages

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
    
    public func perform<Request: OpenAIRequest>(request: Request, completion: @escaping (Result<Request.Response, Error>) -> Void, didCompleteStreaming: ((Error?) -> Void)? = nil) {
        Task {
            if request.stream { do { for try await response in perform(request: request) { completion(.success(response)) }; didCompleteStreaming?(nil) } catch { didCompleteStreaming?(error) } }
            else { do { completion(.success(try await perform(request: request))) } catch { completion(.failure(error))}}
        }
    }

    private func perform<Request: OpenAIRequest>(request: Request) async throws -> Request.Response {
        var httpRequest = prepareRequest(path: Request.path)
        do { httpRequest.httpBody = try JSONEncoder().encode(request) } catch { throw OpenAIError.invalidData }
//        if request.stream { for try await chunk in streamManager.stream(task: session.dataTask(with: httpRequest))/* reduce into single result */ }
        return try await perform(request: httpRequest)
    }

    private func perform<Request: OpenAIRequest>(request: Request) -> AsyncThrowingStream<Request.Response, Error> {
        var httpRequest = prepareRequest(path: Request.path)
        do { httpRequest.httpBody = try JSONEncoder().encode(request) }
        catch { return AsyncThrowingStream { $0.finish(throwing: OpenAIError.invalidData) } }
        if request.stream { return streamManager.stream(task: session.dataTask(with: httpRequest)) }
        else { return AsyncThrowingStream { cont in perform(request: httpRequest) { cont.yield(with: $0) }}}
    }

    // gets called when streaming call is passed a non-stream configuration
    private func perform<Response: Decodable>(request: URLRequest, completion: @escaping (Result<Response, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(OpenAIError.requestFailed(error))) }
            guard httpResponse.statusCode == 200 else { return completion(.failure(OpenAIError.responseUnsuccessful(statusCode: httpResponse.statusCode, data.flatMap { OpenAI.decodeError(data: $0) }))) }
            guard let data = data else { return completion(.failure(OpenAIError.invalidData)) }
            OpenAI.decode(completion: completion)(data)
        }.resume()
    }

    // Should fail when request is configured to be a stream but passed to non-stream method.
    private func perform<Response: Decodable>(request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw OpenAIError.requestFailed(nil) }
        guard httpResponse.statusCode == 200 else { throw OpenAIError.responseUnsuccessful(statusCode: httpResponse.statusCode, OpenAI.decodeError(data: data)) }
        return try OpenAI.decodeResponse(data: data)
    }

    private func prepareRequest(path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    internal class StreamSessionManager: NSObject, URLSessionDataDelegate {
        private var didReceiveEvent: ((Data) -> Void)?
        private var didCompleteStream: ((Error?) -> Void)?
        private var task: URLSessionDataTask?
        
        func stream<Response: Decodable>(task: URLSessionDataTask, eventHandler: @escaping (Result<Response, Error>) -> Void, didCompleteStream: ((Error?) -> Void)? = nil) {
            didReceiveEvent = decode(completion: eventHandler)
            self.didCompleteStream = { [unowned self] error in
                didCompleteStream?(error)
                (self.task, self.didReceiveEvent, self.didCompleteStream) = (nil, nil, nil)
            }
            self.task = task; task.resume()
        }


        func stream<Response: Decodable>(task: URLSessionDataTask) -> AsyncThrowingStream<Response, Error> {
            return AsyncThrowingStream { continuation in
                didReceiveEvent = { continuation.yield(with: OpenAI.decode(data: $0)) }
                didCompleteStream = { continuation.finish(throwing: $0) }
                continuation.onTermination = { @Sendable _ in (self.task, self.didReceiveEvent, self.didCompleteStream) = (nil, nil, nil) }
                self.task = task; task.resume()
            }
        }
        
        internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            if let error = decodeError(data: data) { return didCompleteStream?(error) ?? () }
            guard let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") else { return }
            for line in lines where line.hasPrefix("data:") {
                if !line.contains("[DONE]") { didReceiveEvent?(Data(String(line.dropFirst(5)).utf8)) }
            }
        }

        internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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
        return (self as? StreamableRequest)?.stream ?? false
    }
}

internal protocol StreamableRequest: Encodable {
    var stream: Bool? { get }
}

public enum OpenAIError: Error {
    case invalidData, streamParsingFailure, invalidURL
    case requestFailed(Error?)
    case jsonParsingFailure(Error)
    case responseUnsuccessful(statusCode: Int, Error?)
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
    static func decode<Response: Decodable>(completion: @escaping (Result<Response, Error>) -> Void) -> (Data) -> Void {
        return { completion(decode(data: $0)) }
    }

    static func decode<Response: Decodable>(data: Data) -> Result<Response, Error> {
        let d = JSONDecoder(); do { return .success(try decodeResponse(data: data, decoder: d)) } catch { return .failure(error as! OpenAIError) }
    }

    static func decodeResponse<Response: Decodable>(data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> Response {
        do { return try decoder.decode(Response.self, from: data) } catch { throw decodeError(data: data, decoder: decoder) ?? .jsonParsingFailure(error) }
    }

    static func decodeError(data: Data, decoder: JSONDecoder = JSONDecoder()) -> OpenAIError? {
        return (try? decoder.decode(OpenAIError.ErrorResponse.self, from: data)).flatMap { .apiError($0) }
    }
}
