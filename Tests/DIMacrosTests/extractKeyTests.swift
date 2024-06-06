@testable import DIMacros
import SwiftSyntax
import XCTest

final class extractKeyTests: XCTestCase {
    func testExtractedKey() {
        let patterns: [(ExprSyntax, String, UInt)] = [
            ("AnyKey.foo", ".foo", #line),
            (".foo", ".foo", #line),
            ("foo", "foo", #line),
            ("DI.AnyKey.foo", ".foo", #line),
            ("MyKeys.foo", "MyKeys.foo", #line),
            ("MyModule.MyKeys.foo", "MyModule.MyKeys.foo", #line),
        ]
        
        for pattern in patterns {
            XCTAssertEqual(ExtractedKey(pattern.0).description, pattern.1, line: pattern.2)
        }
    }
}
