//
//  NetworkClient.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation

typealias Model = OpenAIChatAPI.Model
typealias Role = OpenAIChatAPI.Role


class NetworkClient: NSObject, URLSessionWebSocketDelegate {
    static let shared = NetworkClient()

    private let keychainService = KeychainService()
    private var openAIChat: OpenAIChatAPI?
    private let userDefaults = UserDefaults.standard
    private var streamCompletion: ((Result<String, OpenAIChatAPI.APIError>) -> Void)?

    override init() {
        super.init()
        if let apiKey = keychainService.getApiKey() {
            openAIChat = OpenAIChatAPI(apiKey: apiKey)
        }
    }

    func sendChatCompletionRequest(messages: [OpenAIChatAPI.Message], model: Model = .gpt4, stream: Bool = false, completion: @escaping (Result<OpenAIChatAPI.ChatCompletionResponse, Error>) -> Void) throws {
        guard let openAIChat = openAIChat else { throw NetworkError.missingApiKey }
        openAIChat.sendChatCompletionRequest(model: model, messages: messages, stream: stream, completion: completion)
    }
    
    func updateApiKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw NetworkError.emptyApiKey
        }
        keychainService.saveApiKey(apiKey: apiKey)
        openAIChat = OpenAIChatAPI(apiKey: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
        case emptyApiKey
    }
}
