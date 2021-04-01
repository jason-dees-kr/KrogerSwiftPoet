import XCTest
@testable import Kroger_Swift_Poet

final class Kroger_Swift_PoetTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Kroger_Swift_Poet().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
