//
//  CoreDataModelTests.swift
//  OpenAITests
//
//  Created by Reid Chatham on 12/20/23.
//

import XCTest
@testable import OpenAIDemo
import OpenAI
import SwiftyJSON

final class CoreDataModelTests: OpenAIDemoTests {

    func testConvertMessageToOpenAIAndBack() throws {
        if let exampleMessage = Message.example(context: PersistenceController.preview.testManagedObjectContext).toOpenAIMessage(),
           let testMessage = exampleMessage.toCoreDataMessage(in: PersistenceController.preview.testManagedObjectContext).toOpenAIMessage() {
            XCTAssert(JSON(try Data.encode(exampleMessage)) == JSON(try Data.encode(testMessage)), "Data consistency not maintained.\n1):\(exampleMessage)\n2):\(testMessage)")
        } else {
            XCTFail("Got nil when converting between core data and OpenAI-Swift models.")
        }
    }

    func testConvertConversationToOpenAIMessages() throws {
        let exampleConversation = Conversation.example(context: PersistenceController.preview.testManagedObjectContext)
        let messages = exampleConversation.toOpenAIMessages()
        XCTAssertEqual(messages[0].content.text, "You are a friendly chatbot designed to be helpful. Always be nice, but if you don\'t have a clear understanding of what should come next, try to indicate that.")
        XCTAssertEqual(messages[0].role, .system)
        XCTAssertEqual(messages[1].content.text, "Hello, how are you?")
        XCTAssertEqual(messages[1].role, .user)
        XCTAssertEqual(messages[2].content.text, "I'm doing well, thank you. How can I help you today?")
        XCTAssertEqual(messages[2].role, .assistant)
    }
}
