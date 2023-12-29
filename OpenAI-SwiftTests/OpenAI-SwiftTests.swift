//
//  OpenAI-SwiftTests.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 12/6/23.
//

import XCTest
@testable import OpenAI_Swift

class OpenAI_SwiftTests: XCTestCase {

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

    func getData(filename: String) throws -> Data? {
        return try Data.getJsonData(filename: filename, bundle: Bundle(for: type(of: self)))
    }
}

extension Data {
    var string: String {
        return String(data: self, encoding: .utf8)!
    }
    var dictionary: [String: String]? {
        return (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)).flatMap { $0 as? [String: String] }
    }
    static func getJsonData(filename: String, bundle: Bundle) throws -> Data? {
        if let path = bundle.url(forResource: filename, withExtension: "json") {
            return try Data(contentsOf: path)
        }
        return nil
    }
    init(_ encodable: Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self = try encoder.encode(encodable)
    }
}

extension Encodable {
    func data() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

class MockURLProtocol: URLProtocol {
    typealias MockNetworkHandler = (URLRequest) throws -> (
        result: Result<Data, Error>, statusCode: Int?
    )
    public static var mockNetworkHandlers: [String: MockNetworkHandler] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = try! MockURLProtocol.mockNetworkHandlers.removeValue(forKey: request.url!.lastPathComponent)!(request)

        if let statusCode = response.statusCode {
            let httpURLResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            self.client?.urlProtocol(
                 self,
                 didReceive: httpURLResponse,
                 cacheStoragePolicy: .notAllowed
            )
        }

        switch response.result {
        case let .success(data):
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)

        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

struct MockRequest: OpenAIRequest, Encodable {
    typealias Response = MockResponse
    static var path: String = "test"
}

struct MockResponse: Codable {
    var status: String
}
