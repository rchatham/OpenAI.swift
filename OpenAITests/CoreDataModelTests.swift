//
//  CoreDataModelTests.swift
//  OpenAITests
//
//  Created by Reid Chatham on 12/20/23.
//

import XCTest
@testable import OpenAI
import OpenAI_Swift
import SwiftyJSON

final class CoreDataModelTests: OpenAITests {

    func testConvertMessageToOpenAIAndBack() throws {
        if let exampleMessage = Message.example(context: PersistenceController.preview.testManagedObjectContext).toOpenAIMessage(),
           let testMessage = exampleMessage.toCoreDataMessage(in: PersistenceController.preview.testManagedObjectContext).toOpenAIMessage() {
            XCTAssert(JSON(try Data.encode(exampleMessage)) == JSON(try Data.encode(testMessage)), "Data consistency not maintained.\n1):\(exampleMessage)\n2):\(testMessage)")
        } else {
            XCTFail("Got nil when converting between core data and OpenAI-Swift models.")
        }
    }

}
