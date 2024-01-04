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
    private var openAIChat: OpenAI?
    private let userDefaults = UserDefaults.standard
    private var streamCompletion: ((Result<String, OpenAIError>) -> Void)?

    override init() {
        super.init()
        if let apiKey = keychainService.getApiKey() { openAIChat = OpenAI(apiKey: apiKey) }
    }

    func sendChatCompletionRequest(messages: [OpenAI.Message], model: Model = .gpt4, stream: Bool = false, tools: [OpenAI.ChatCompletionRequest.Tool]? = nil, toolChoice: OpenAI.ChatCompletionRequest.ToolChoice? = nil, completion: @escaping (Result<OpenAI.ChatCompletionResponse, Error>) -> Void, streamCompletion: @escaping (Error?) -> Void = {_ in}) {
//        print("messages: \(messages)")
        guard let openAIChat = openAIChat else { return completion(.failure(NetworkError.missingApiKey)) }
        let request = OpenAI.ChatCompletionRequest(model: model, messages: messages, stream: stream, tools: tools, tool_choice: toolChoice)
        openAIChat.perform(request: request) {
            completion($0.mapError{$0})
        } didCompleteStreaming: {
            print($0?.localizedDescription ?? "Stream completed")
            streamCompletion($0)
        }
    }

    func updateApiKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else { throw NetworkError.emptyApiKey }
        keychainService.saveApiKey(apiKey: apiKey)
        openAIChat = OpenAI(apiKey: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
        case emptyApiKey
    }
}

