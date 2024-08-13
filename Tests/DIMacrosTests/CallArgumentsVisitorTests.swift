@testable import DIMacros
import SwiftDiagnostics
import SwiftSyntax
import XCTest

final class CallArgumentsVisitorTests: XCTestCase {
    func testBasic() {
        let provide = FoundProvides(
            arguments: .init(key: .init(".foo" as ExprSyntax)),
            callExpression: "getFoo()"
        )

        let expr = """
        A(foo: getFoo())
        """ as ExprSyntax

        let visitor = CallArgumentsVisitor(providings: [provide])
        visitor.walk(expr)
        XCTAssertEqual(visitor.diagnostics.count, 1)

        if case .replace(let old, let new) = visitor.diagnostics.flatMap(\.fixIts).flatMap(\.changes).first {
            XCTAssertEqual(old.description, "getFoo()")
            XCTAssertEqual(new.description, "get(.foo)")
        } else {
            XCTFail()
        }
    }

    func testSelf() {
        let provide = FoundProvides(
            arguments: .init(key: .init(".foo" as ExprSyntax)),
            callExpression: "getFoo()"
        )

        let expr = """
        A(foo: self.getFoo())
        """ as ExprSyntax

        let visitor = CallArgumentsVisitor(providings: [provide])
        visitor.walk(expr)
        XCTAssertEqual(visitor.diagnostics.count, 1)

        if case .replace(let old, let new) = visitor.diagnostics.flatMap(\.fixIts).flatMap(\.changes).first {
            XCTAssertEqual(old.description, "self.getFoo()")
            XCTAssertEqual(new.description, "self.get(.foo)")
        } else {
            XCTFail()
        }
    }

    func testMemberAccess() {
        let provide = FoundProvides(
            arguments: .init(key: .init(".foo" as ExprSyntax)),
            callExpression: "getFoo()"
        )

        let expr = """
        B(bar: getFoo().bar)
        """ as ExprSyntax

        let visitor = CallArgumentsVisitor(providings: [provide])
        visitor.walk(expr)
        XCTAssertEqual(visitor.diagnostics.count, 1)

        if case .replace(let old, let new) = visitor.diagnostics.flatMap(\.fixIts).flatMap(\.changes).first {
            XCTAssertEqual(old.description, "getFoo().bar")
            XCTAssertEqual(new.description, "get(.foo).bar")
        } else {
            XCTFail()
        }
    }

    func testConfusingPrefix() {
        let provide = FoundProvides(
            arguments: .init(key: .init(".foo" as ExprSyntax)),
            callExpression: "foo"
        )

        let expr = """
        A(foo: fooValue)
        """ as ExprSyntax

        let visitor = CallArgumentsVisitor(providings: [provide])
        visitor.walk(expr)
        XCTAssertEqual(visitor.diagnostics.count, 0)
    }

    func testEscapeByTuple() {
        let provide = FoundProvides(
            arguments: .init(key: .init(".foo" as ExprSyntax)),
            callExpression: "foo"
        )

        let expr = """
        A(foo: (foo))
        """ as ExprSyntax

        let visitor = CallArgumentsVisitor(providings: [provide])
        visitor.walk(expr)
        XCTAssertEqual(visitor.diagnostics.count, 0)
    }
}
