//
//  MockURLProtocol.swift
//  OpenAI-SwiftTests
//
//  Created by Reid Chatham on 12/30/23.
//

import Foundation

class MockURLProtocol: URLProtocol {
    typealias MockNetworkHandler = (URLRequest) throws -> (
        result: Result<Data, Error>, statusCode: Int?
    )
    public static var mockNetworkHandlers: [String: MockNetworkHandler] = [:]

    override class func canInit(with request: URLRequest) -> Bool { mockNetworkHandlers[request.endpoint] != nil }
    override class func canInit(with task: URLSessionTask) -> Bool { mockNetworkHandlers[task.endpoint] != nil }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = try! MockURLProtocol.mockNetworkHandlers.removeValue(forKey: request.endpoint)!(request)

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

extension URLRequest {
    var endpoint: String { url!.pathComponents[2...].joined(separator: "/") }
}

extension URLSessionTask {
    var endpoint: String { currentRequest!.endpoint }
}
