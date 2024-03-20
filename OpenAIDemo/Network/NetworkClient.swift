//
//  NetworkClient.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation
import OpenAI

typealias Model = OpenAI.Model
typealias Role = OpenAI.Message.Role


class NetworkClient: NSObject, URLSessionWebSocketDelegate {
    static let shared = NetworkClient()

    private let keychainService = KeychainService()
    private var openAIClient: OpenAI?
    private let userDefaults = UserDefaults.standard
    private var streamCompletion: ((Result<String, OpenAIError>) -> Void)?

    override init() {
        super.init()
        if let apiKey = keychainService.getApiKey() { openAIClient = OpenAI(apiKey: apiKey) }
    }

    func performChatCompletionRequest(messages: [OpenAI.Message], model: Model = .gpt4, stream: Bool = false, tools: [OpenAI.ChatCompletionRequest.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil) async throws -> OpenAI.ChatCompletionResponse {
        guard let openAIClient = openAIClient else { throw NetworkError.missingApiKey }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        return try await openAIClient.perform(request: request)
    }

    func streamChatCompletionRequest(messages: [OpenAI.Message], model: Model = .gpt4, stream: Bool = false, tools: [OpenAI.ChatCompletionRequest.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil) throws -> AsyncThrowingStream<OpenAI.ChatCompletionResponse, Error> {
        guard let openAIClient = openAIClient else { throw NetworkError.missingApiKey }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        return openAIClient.stream(request: request)
    }

    func sendChatCompletionRequest(messages: [OpenAI.Message], model: Model = .gpt4, stream: Bool = false, tools: [OpenAI.ChatCompletionRequest.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil, completion: @escaping (Result<OpenAI.ChatCompletionResponse, Error>) -> Void, streamCompletion: @escaping (Error?) -> Void = {_ in}) throws {
//        print("messages: \(messages)")
        guard let openAIClient = openAIClient else { throw NetworkError.missingApiKey }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        openAIClient.perform(request: request) {
            completion($0.mapError{$0})
        } didCompleteStreaming: {
            print($0?.localizedDescription ?? "Stream completed")
            streamCompletion($0)
        }
    }

    func updateApiKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else { throw NetworkError.emptyApiKey }
        keychainService.saveApiKey(apiKey: apiKey)
        openAIClient = OpenAI(apiKey: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
        case emptyApiKey
    }
}

