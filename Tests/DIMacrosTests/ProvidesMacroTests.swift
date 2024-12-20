import DIMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ProvidesMacroTests: XCTestCase {
    let macros: [String: any Macro.Type] = [
        "Provides": ProvidesMacro.self,
    ]

    func testFunc() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.apiClient)
    func apiClient() -> APIClient {
        let config = get(.apiConfig)
        return APIClient(config: config)
    }
}
""", expandedSource: """
struct RootComponent {
    func apiClient() -> APIClient {
        let config = get(.apiConfig)
        return APIClient(config: config)
    }

    @Sendable private static func __provide__apiClient(`self`: Self) -> APIClient {
        let instance = self.apiClient()
        assert({
            let check = DI.VariantChecker(.apiClient)
            return check(instance)
        }())
        return instance
    }
}
""", macros: macros
        )
    }

    func testFuncWithArgs() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.apiClient)
    func apiClient(baseURL: URL) -> APIClient {
        APIClient(baseURL: baseURL)
    }
}
""", expandedSource: """
struct RootComponent {
    func apiClient(baseURL: URL) -> APIClient {
        APIClient(baseURL: baseURL)
    }
}
""", diagnostics: [
    .init(
        message: "Provider function cannot have the arguments.",
        line: 2,
        column: 5,
        severity: .error
    )
], macros: macros
        )
    }

    func testStoredLet() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.urlSession)
    let urlSession: URLSession
}
""", expandedSource: """
struct RootComponent {
    let urlSession: URLSession

    @Sendable private static func __provide__urlSession(`self`: Self) -> URLSession {
        let instance = self.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""", macros: macros
        )
    }

    func testStoredVar() {
        assertMacroExpansion(
"""
struct RootComponent {
    @Provides(.urlSession)
    var urlSession: URLSession
}
""",
expandedSource: """
struct RootComponent {
    var urlSession: URLSession

    @Sendable private static func __provide__urlSession(`self`: Self) -> URLSession {
        let instance = self.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""",
macros: macros
        )
    }

    func testComputedVar() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.urlSession)
    var urlSession: URLSession {
        .shared
    }
}
""", expandedSource: """
struct RootComponent {
    var urlSession: URLSession {
        .shared
    }

    @Sendable private static func __provide__urlSession(`self`: Self) -> URLSession {
        let instance = self.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""", macros: macros
        )
    }

    func testComputedVarAccessors() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.urlSession)
    var urlSession: URLSession {
        set {
            fatalError()
        }
        get {
            .shared
        }
    }
}
""", expandedSource: """
struct RootComponent {
    var urlSession: URLSession {
        set {
            fatalError()
        }
        get {
            .shared
        }
    }

    @Sendable private static func __provide__urlSession(`self`: Self) -> URLSession {
        let instance = self.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""", macros: macros
        )
    }

    func testMultipleBinding() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.foo)
    let foo: Foo, bar: Bar
}
""", expandedSource: """
struct RootComponent {
    let foo: Foo, bar: Bar
}
""", diagnostics: [
    .init(message: "peer macro can only be applied to a single variable", line: 2, column: 5),
], macros: macros
        )
    }
}
