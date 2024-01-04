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
        api = OpenAI(testURLSessionConfiguration: config)
    }

    override func tearDown() {
        MockURLProtocol.mockNetworkHandlers.removeAll()
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func test() throws {
        MockURLProtocol.mockNetworkHandlers[MockRequest.path] = { request in
            return (.success(try MockResponse(status: "success").data()), 200)
        }
        let expectation = XCTestExpectation(description: "request returned")
        api.perform(request: MockRequest()) { result in
            if case .success(let success) = result {
                XCTAssertEqual(success.status, "success")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1)
    }

    func testStream() throws {
        MockURLProtocol.mockNetworkHandlers[MockStreamRequest.path] = { request in
            return (.success(try MockStreamResponse(status: "success").streamData()), 200)
        }
        let resultReturned = XCTestExpectation(description: "result returned")
        let didCompleteStreaming = XCTestExpectation(description: "did complete streaming")
        api.perform(request: MockStreamRequest()) { result in
            if case .success(let success) = result {
                XCTAssertEqual(success.status, "success")
            } else {
                XCTFail("failed to return result")
            }
            resultReturned.fulfill()
        } didCompleteStreaming: { error in
            XCTAssertNil(error)
            didCompleteStreaming.fulfill()
        }
        wait(for: [resultReturned, didCompleteStreaming], timeout: 10)
    }

    func testChatStream() throws {
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
        let resultReturned = XCTestExpectation(description: "result returned")
        let didCompleteStreaming = XCTestExpectation(description: "did complete streaming")
        api.perform(request: OpenAI.ChatCompletionRequest(model: .gpt35Turbo, messages: [.init(role: .user, content: "Hi")], stream: true)) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response.id, "testid")
            } else {
                XCTFail("failed to return result")
            }
            resultReturned.fulfill()
        } didCompleteStreaming: { error in
            XCTAssertNil(error)
            didCompleteStreaming.fulfill()
        }
        wait(for: [resultReturned, didCompleteStreaming], timeout: 10)
    }
}

extension XCTestCase {
    func getData(filename: String) throws -> Data? {
        return try Data.getData(filename: filename, bundle: Bundle(for: type(of: self)))
    }
}

struct MockRequest: OpenAIRequest, Encodable {
    typealias Response = MockResponse
    static var path = "test"
}

struct MockResponse: Codable {
    var status: String
}

struct MockStreamRequest: OpenAIRequest, StreamableRequest, Encodable {
    typealias Response = MockStreamResponse
    static var path = "test"
    var stream: Bool? = true
}

struct MockStreamResponse: Codable, StreamableResponse {
    var status: String
}

extension OpenAI.ChatCompletionResponse: StreamableResponse {}

protocol StreamableResponse: Encodable {}
extension StreamableResponse {
    func streamData() throws -> Data {
        let jsonString = try data().string
        return ("data: " + jsonString).data(using: .utf8)!
    }
}

