import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Kroger_Swift_PoetTests.allTests),
    ]
}
#endif
