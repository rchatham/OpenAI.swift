//
//  OpenAITests.swift
//  OpenAITests
//
//  Created by Reid Chatham on 12/6/23.
//

import XCTest
@testable import OpenAI

class OpenAITests: XCTestCase {

    var api: OpenAI!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        api = OpenAI(apiKey: "").configure(testURLSessionConfiguration: config)
    }

    override func tearDown() {
        MockURLProtocol.mockNetworkHandlers.removeAll()
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func test() async throws {
        MockURLProtocol.mockNetworkHandlers[MockRequest.path] = { request in
            return (.success(try MockResponse(status: "success").data()), 200)
        }
        let response = try await api.perform(request: MockRequest())
        XCTAssertEqual(response.status, "success")
    }

    func testStream() async throws {
        MockURLProtocol.mockNetworkHandlers[MockRequest.path] = { request in
            return (.success(try MockResponse(status: "success").streamData()), 200)
        }
        var results: [MockResponse] = []
        for try await response in api.stream(request: MockRequest(stream: true)) {
            results.append(response)
        }
        let content = results.reduce("") { $0 + ($1.status) }
        XCTAssertEqual(content, "success")
    }

    func testChatStream() async throws {
        MockURLProtocol.mockNetworkHandlers[OpenAI.ChatCompletionRequest.path] = { request in
            return (.success(try OpenAI.ChatCompletionResponse(
                id: "testid",
                object: "chat.completion.chunk",
                created: 0,
                model: "gpt4",
                system_fingerprint: "some-system-fingerprint-klabs9fg72n",
                choices: [.init(
                    index: 0,
                    message: nil,
                    finish_reason: nil,
                    delta: .init(
                        role: .assistant,
                        content: "Hello, how are you?",
                        tool_calls: nil))],
                usage: .init(prompt_tokens: 50, completion_tokens: 50, total_tokens: 100)).streamData()), 200)
        }
        var results: [OpenAI.ChatCompletionResponse] = []
        for try await response in api.stream(request: OpenAI.ChatCompletionRequest(model: .gpt35Turbo, messages: [.init(role: .user, content: "Hi")], stream: true)) {
            results.append(response)
        }
        let content = results.reduce("") { $0 + ($1.choices[0].delta?.content ?? "") }
        XCTAssertEqual(results[0].id, "testid")
        XCTAssertEqual(content, "Hello, how are you?")
    }

    func testChatStreamResponse() async throws {
        MockURLProtocol.mockNetworkHandlers[OpenAI.ChatCompletionRequest.path] = { request in
            return (.success(try self.getData(filename: "assistant_response_stream", fileExtension: "txt")!), 200)
        }
        var results: [OpenAI.ChatCompletionResponse] = []
        for try await response in api.stream(request: OpenAI.ChatCompletionRequest(model: .gpt35Turbo, messages: [.init(role: .user, content: "Hi")], stream: true)) {
            results.append(response)
        }
        let content = results.reduce("") { $0 + ($1.choices[0].delta?.content ?? "") }
        XCTAssertEqual(results[0].choices[0].delta?.role, .assistant)
        XCTAssertEqual(content, "Sure, I can help with that. Could you please specify the location?")
        XCTAssertEqual(results[16].choices[0].finish_reason, .stop)
    }

    func testToolCallStreamResponse() async throws {
        MockURLProtocol.mockNetworkHandlers[OpenAI.ChatCompletionRequest.path] = { request in
            return (.success(try self.getData(filename: "tool_call_stream", fileExtension: "txt")!), 200)
        }
        var results: [OpenAI.ChatCompletionResponse] = []
        for try await response in api.stream(request: OpenAI.ChatCompletionRequest(model: .gpt35Turbo, messages: [.init(role: .user, content: "Hi")], stream: true)) {
            results.append(response)
        }
        XCTAssertEqual(results[0].choices[0].delta?.role, .assistant)
        XCTAssertEqual(results[0].choices[0].delta?.tool_calls?[0].function.name, "getCurrentWeather")
        let arguments = results.reduce("") { $0 + ($1.choices[0].delta?.tool_calls?[0].function.arguments ?? "") }
        XCTAssertEqual(arguments, "{\n  \"format\": \"fahrenheit\",\n  \"location\": \"Bangkok\"\n}")
        XCTAssertEqual(results[19].choices[0].finish_reason, .tool_calls)
    }
}

