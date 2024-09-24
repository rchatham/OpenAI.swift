//
//  ChatCompletionRequestTests.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 12/15/23.
//

import XCTest
@testable import OpenAI
import SwiftyJSON

final class ChatCompletionRequestTests: XCTestCase {
    func testChatCompletionRequestDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.ChatCompletionRequest, Error>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "chat_completion_request")!)
    }

    func testChatCompletionRequestWithImageDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.ChatCompletionRequest, Error>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "chat_completion_request_with_image")!)
    }

    func testChatCompletionRequestWithFunctionsDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.ChatCompletionRequest, Error>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "chat_completion_request_with_functions")!)
    }

    func testChatCompletionRequestEncodable() throws {
        let request = OpenAI.ChatCompletionRequest(
            model: .gpt4_turbo,
            messages: [
                .init(role: .system, content: "You are a helpful assistant."),
                .init(role: .user, content: "Hello!")
            ])
        let data = try request.data()
        let json = JSON(data)
        let testData = try getData(filename: "chat_completion_request")!
        let testJson = JSON(testData)
        XCTAssert(json == testJson, "failed to correctly encode the data")
    }

    func testChatCompletionRequestWithImageEncodable() throws {
        let request = OpenAI.ChatCompletionRequest(
            model: .gpt4_turbo,
            messages: [
                try .init(role: .user, content: OpenAI.Message.Content.array([
                    .text(.init(text: "What's in this image?")),
                    .image(.init(image_url: .init(url: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg")))
                ]))
            ])
        let data = try request.data()
        let json = JSON(data)
        let testData = try getData(filename: "chat_completion_request_with_image")!
        let testJson = JSON(testData)
        XCTAssert(json == testJson, "failed to correctly encode the data")
    }

    func testChatCompletionRequestWithFunctionsEncodable() throws {
        let request = OpenAI.ChatCompletionRequest(
            model: .gpt4_turbo,
            messages: [
                .init(role: .system, content: "You are a helpful assistant."),
                .init(role: .user, content: "Hello!")
            ],
            tools: [
                .function(.init(
                    name: "get_current_weather",
                    description: "Get the current weather",
                    parameters: .init(
                        properties: [
                            "location": .init(
                                type: "string",
                                description: "The city and state, e.g. San Francisco, CA"),
                            "format": .init(
                                type: "string",
                                enumValues: ["celsius", "fahrenheit"],
                                description: "The temperature unit to use. Infer this from the users location.")
                        ],
                        required: ["location", "format"]))),
                .function(.init(
                    name: "get_n_day_weather_forecast",
                    description: "Get an N-day weather forecast",
                    parameters: .init(
                        properties: [
                            "location": .init(
                                type: "string",
                                description: "The city and state, e.g. San Francisco, CA"
                            ),
                            "format": .init(
                                type: "string",
                                enumValues: ["celsius", "fahrenheit"],
                                description: "The temperature unit to use. Infer this from the users location."
                            ),
                            "num_days": .init(
                                type: "integer",
                                description: "The number of days to forecast"
                            )
                        ],
                        required: ["location", "format", "num_days"])))
            ])
        let data = try request.data()
        let json = JSON(data)
        let testData = try getData(filename: "chat_completion_request_with_functions")!
        let testJson = JSON(testData)
        XCTAssert(json == testJson, "failed to correctly encode the data")
    }
}
