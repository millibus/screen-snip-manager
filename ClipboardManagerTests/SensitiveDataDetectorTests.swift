import XCTest
@testable import ClipboardManager

final class SensitiveDataDetectorTests: XCTestCase {
    func testDetectsKnownTokenPrefixes() {
        XCTAssertTrue(SensitiveDataDetector.shared.isSensitive("ghp_example_not_real_token_value"))
        XCTAssertTrue(SensitiveDataDetector.shared.isSensitive("xoxb-example-placeholder-token"))
        XCTAssertTrue(SensitiveDataDetector.shared.isSensitive("AKIAexamplekey123456"))
    }

    func testDetectsJwtLikePayload() {
        XCTAssertTrue(SensitiveDataDetector.shared.isSensitive("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))
    }

    func testDetectsLongTokenLikeStrings() {
        XCTAssertTrue(SensitiveDataDetector.shared.isSensitive("A1b2C3d4E5f6G7h8!9J0k1L2m3N4o5P6q7R8s9T0"))
    }

    func testIgnoresShortOrLowEntropyText() {
        XCTAssertFalse(SensitiveDataDetector.shared.isSensitive("short-token"))
        XCTAssertFalse(SensitiveDataDetector.shared.isSensitive("just some normal sentence that is long"))
    }

    func testIgnoresUrlsAndJsonAndCode() {
        XCTAssertFalse(SensitiveDataDetector.shared.isSensitive("https://github.com/user/repo/blob/main/README.md"))
        XCTAssertFalse(SensitiveDataDetector.shared.isSensitive("{\"key\": \"value\", \"count\": 42}"))
        XCTAssertFalse(SensitiveDataDetector.shared.isSensitive("func hello() { print(\"world\") }"))
    }
}
