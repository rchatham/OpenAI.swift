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

    func performChatCompletionRequest(messages: [OpenAI.Message], model: Model = UserDefaults.model, stream: Bool = false, tools: [OpenAI.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil) async throws -> OpenAI.ChatCompletionResponse {
        guard let openAIClient = openAIClient else { throw NetworkError.missingApiKey }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        return try await openAIClient.perform(request: request)
    }

    func streamChatCompletionRequest(messages: [OpenAI.Message], model: Model = UserDefaults.model, stream: Bool = false, tools: [OpenAI.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil) throws -> AsyncThrowingStream<OpenAI.ChatCompletionResponse, Error> {
        guard let openAIClient = openAIClient else { throw NetworkError.missingApiKey }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        return openAIClient.stream(request: request)
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

