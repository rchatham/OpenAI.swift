//
//  CoreDataModelTests.swift
//  OpenAITests
//
//  Created by Reid Chatham on 12/20/23.
//

import XCTest
import OpenAI
import OpenAI_Swift

final class CoreDataModelTests: OpenAITests {

    func testConvertMessageFromOpenAIAndBack() throws {
        decode { (result: Result<OpenAI.ChatCompletionRequest, Error>) in
            switch result {
            case .success(_): break
            case .failure(let error):
                XCTFail("failed to decode data \(error.localizedDescription)")
            }
        }(try getData(filename: "chat_completion_request")!)
    }

}
