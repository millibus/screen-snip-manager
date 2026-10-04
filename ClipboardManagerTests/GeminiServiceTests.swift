import Foundation
import XCTest
@testable import ClipboardManager

private final class GeminiMockProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (URLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.unsupportedURL) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class GeminiServiceTests: XCTestCase {
    private var session: URLSession!
    private var service: GeminiService!
    private let fakeKey = "synthetic-test-key"
    private let image = Data([0x89, 0x50, 0x4e, 0x47])

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GeminiMockProtocol.self]
        session = URLSession(configuration: configuration)
        service = GeminiService(session: session)
        GeminiMockProtocol.handler = { _ in
            XCTFail("Unexpected request")
            throw URLError(.unsupportedURL)
        }
    }
    override func tearDown() {
        session.invalidateAndCancel()
        GeminiMockProtocol.handler = nil
    }

    private func reply(to request: URLRequest, status: Int = 200, body: String) -> (URLResponse, Data) {
        (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
    }
    private let success = "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"```html\\n<div>Demo</div>\\n```\"}]}}]}"

    func testDefaultModelAndHeaderAuthenticationPreserveImagePayload() async throws {
        GeminiMockProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "generativelanguage.googleapis.com")
            XCTAssertEqual(request.url?.path, "/v1beta/models/gemini-3.8-flash:generateContent")
            XCTAssertNil(request.url?.query)
            XCTAssertFalse(request.url!.absoluteString.contains(self.fakeKey))
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), self.fakeKey)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var bytes = [UInt8](repeating: 0, count: 4096)
                var data = Data()
                while stream.hasBytesAvailable {
                    let count = stream.read(&bytes, maxLength: bytes.count)
                    if count <= 0 { break }
                    data.append(contentsOf: bytes.prefix(count))
                }
                body = data
            }
            let json = try JSONSerialization.jsonObject(with: XCTUnwrap(body)) as! [String: Any]
            let contents = json["contents"] as! [[String: Any]]
            let parts = contents[0]["parts"] as! [[String: Any]]
            let inline = parts[1]["inlineData"] as! [String: String]
            XCTAssertEqual(inline["mimeType"], "image/png")
            XCTAssertEqual(inline["data"], self.image.base64EncodedString())
            return self.reply(to: request, body: self.success)
        }
        let code = try await service.generateUICode(from: image, apiKey: fakeKey)
        XCTAssertEqual(code, "<div>Demo</div>")
    }

    func testConfiguredModelAndWhitespace() async throws {
        GeminiMockProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/v1beta/models/gemini-custom-supported:generateContent")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), self.fakeKey)
            return self.reply(to: request, body: self.success)
        }
        _ = try await service.generateUICode(from: image, apiKey: " \(fakeKey) ", model: " gemini-custom-supported ")
    }

    func testBlankModelUsesDefault() async throws {
        GeminiMockProtocol.handler = { request in
            XCTAssertTrue(request.url!.path.contains(GeminiService.defaultModel))
            return self.reply(to: request, body: self.success)
        }
        _ = try await service.generateUICode(from: image, apiKey: fakeKey, model: " \n")
    }

    func testMissingKeyStopsBeforeTransport() async {
        do {
            _ = try await service.generateUICode(from: image, apiKey: " \n")
            XCTFail("Expected missing key")
        } catch GeminiError.missingAPIKey {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testHeaderInjectionStopsBeforeTransport() async {
        do {
            _ = try await service.generateUICode(from: image, apiKey: "fake\r\nInjected: value")
            XCTFail("Expected invalid key")
        } catch GeminiError.invalidAPIKey {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testInvalidModelStopsBeforeTransport() async {
        for model in ["https://example.com", "gemini-test?key=fake", "gemini-test/path", "gemini-%2Ftest", "gemini-💥"] {
            do {
                _ = try await service.generateUICode(from: image, apiKey: fakeKey, model: model)
                XCTFail("Expected invalid model")
            } catch GeminiError.invalidModel {} catch { XCTFail("Unexpected error: \(error)") }
        }
    }

    func testProviderErrorsDoNotEchoKeyOrPrivateBody() async {
        for status in [400, 401, 404, 429, 500] {
            GeminiMockProtocol.handler = { request in
                self.reply(to: request, status: status, body: "\(self.fakeKey) private-provider-body")
            }
            do {
                _ = try await service.generateUICode(from: image, apiKey: fakeKey)
                XCTFail("Expected HTTP failure")
            } catch GeminiError.apiError(let actual) {
                XCTAssertEqual(actual, status)
                let message = GeminiError.apiError(actual).localizedDescription
                XCTAssertFalse(message.contains(fakeKey))
                XCTAssertFalse(message.contains("private-provider-body"))
            } catch { XCTFail("Unexpected error: \(error)") }
        }
    }

    func testMalformedBlockedAndEmptyResponsesFail() async {
        for body in ["not-json", "{}", "{\"candidates\":[]}", "{\"promptFeedback\":{\"blockReason\":\"SAFETY\"}}", "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\" \"}]}}]}"] {
            GeminiMockProtocol.handler = { self.reply(to: $0, body: body) }
            do {
                _ = try await service.generateUICode(from: image, apiKey: fakeKey)
                XCTFail("Expected invalid response")
            } catch GeminiError.invalidResponse {} catch { XCTFail("Unexpected error: \(error)") }
        }
    }

    func testThoughtPartsAreExcludedAndTextPartsJoined() async throws {
        GeminiMockProtocol.handler = { request in
            self.reply(to: request, body: "{\"candidates\":[{\"content\":{\"parts\":[{\"thought\":true,\"text\":\"reasoning\"},{\"text\":\"<div>\"},{\"text\":\"Demo</div>\"}]}}]}")
        }
        let code = try await service.generateUICode(from: image, apiKey: fakeKey)
        XCTAssertEqual(code, "<div>Demo</div>")
    }

    func testTransportErrorsDoNotEchoPrivateDescriptions() async {
        GeminiMockProtocol.handler = { _ in
            throw NSError(domain: "synthetic", code: 1, userInfo: [NSLocalizedDescriptionKey: self.fakeKey])
        }
        do {
            _ = try await service.generateUICode(from: image, apiKey: fakeKey)
            XCTFail("Expected network error")
        } catch GeminiError.networkError {
            XCTAssertFalse(GeminiError.networkError.localizedDescription.contains(fakeKey))
        } catch { XCTFail("Unexpected error: \(error)") }
    }
}
