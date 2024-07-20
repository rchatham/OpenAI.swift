//
//  OpenAIDemoTests.swift
//  OpenAIDemoTests
//
//  Created by Reid Chatham on 1/20/23.
//

import XCTest
@testable import OpenAIDemo
import OpenAI

class OpenAIDemoTests: XCTestCase {}

extension XCTestCase {
    func getData(filename: String) throws -> Data? {
        return try Data.getJsonData(filename: filename, bundle: Bundle(for: type(of: self)))
    }

    func decode<Response: Decodable>(completion: @escaping (Result<Response, Error>) -> Void) -> (Data) -> Void {
        return { data in
            let d = JSONDecoder()
            do { completion(.success(try d.decode(Response.self, from: data))) }
            catch { completion(.failure(error)) }
        }
    }
}
