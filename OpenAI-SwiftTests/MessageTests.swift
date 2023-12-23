//
//  MessageTests.swift
//  openai-swiftTests
//
//  Created by Reid Chatham on 12/15/23.
//

import XCTest
import OpenAI_Swift

final class MessageTests: OpenAI_SwiftTests {

    func testSystemMessageDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.Message, OpenAIError>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "system_message")!)
    }

    func testUserMessageDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.Message, OpenAIError>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "user_message")!)
    }

    func testUserMessageWithImageDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.Message, OpenAIError>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "user_message_with_image")!)
    }
    
    func testAssistantMessageDecodable() throws {
        OpenAI.decode { (result: Result<OpenAI.Message, OpenAIError>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "assistant_message")!)
    }
    
    func testSystemMessageEncodable() throws {
        let userMessage = OpenAI.Message(role: .system, content: "You are a helpful assistant.")
        let json = try Data.encode(userMessage)
        let data = try getData(filename: "system_message")!
//        print("encoded:\(json.string)\ndecoded:\(data.string)")
        XCTAssert(json.dictionary == data.dictionary, "system message not encoded correctly")
    }

    func testUserMessageEncodable() throws {
        let userMessage = OpenAI.Message(role: .user, content: "Hello!")
        let json = try Data.encode(userMessage)
        let data = try getData(filename: "user_message")!
//        print("encoded:\(json.string)\ndecoded:\(data.string)")
        XCTAssert(json.dictionary == data.dictionary, "user message not encoded correctly")
    }
}
