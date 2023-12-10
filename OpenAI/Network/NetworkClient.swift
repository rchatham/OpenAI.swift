//
//  NetworkClient.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation
import openai_swift

typealias Model = OpenAI.Model
typealias Role = OpenAI.Role


class NetworkClient: NSObject, URLSessionWebSocketDelegate {
    static let shared = NetworkClient()

    private let keychainService = KeychainService()
    private var openAIChat: OpenAI?
    private let userDefaults = UserDefaults.standard
    private var streamCompletion: ((Result<String, OpenAIError>) -> Void)?

    override init() {
        super.init()
        if let apiKey = keychainService.getApiKey() {
            openAIChat = OpenAI(apiKey: apiKey)
        }
    }

    func sendChatCompletionRequest(messages: [OpenAI.Message], model: Model = .gpt4, stream: Bool = false, completion: @escaping (Result<OpenAI.ChatCompletionResponse, Error>) -> Void) throws {
        guard let openAIChat = openAIChat else { throw NetworkError.missingApiKey }
        openAIChat.performChatCompletionRequest(messages: messages, model: model, stream: stream) { (result: Result<OpenAI.ChatCompletionResponse, OpenAIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response): completion(.success(response))
                case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
    
    func updateApiKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw NetworkError.emptyApiKey
        }
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
