//
//  ChatCompletionResponseTests.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 12/15/23.
//

import XCTest
@testable import OpenAI
import SwiftyJSON

final class ChatCompletionResponseTests: XCTestCase {
    func testChatCompletionResponseDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.ChatCompletionResponse, OpenAIError>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "chat_completion_response")!)
    }

    func testChatCompletionResponseEncodable() throws {
        let response = OpenAI.ChatCompletionResponse(
            id: "chatcmpl-123",
            object: "chat.completion",
            created: 1677652288,
            model: "gpt-3.5-turbo-0613",
            system_fingerprint: "fp_44709d6fcb",
            choices: [.init(
                index: 0,
                message: .init(
                    role: .assistant,
                    content: "Hello there, how may I assist you today?"),
                finish_reason: .stop,
                delta: nil)
            ],
            usage: .init(
                prompt_tokens: 9,
                completion_tokens: 12,
                total_tokens: 21
            )
        )
        let data = try response.data()
        let json = JSON(data)
        let testData = try getData(filename: "chat_completion_response")!
        let testJson = JSON(testData)
        XCTAssert(json == testJson, "failed to correctly encode the data")
    }
}
