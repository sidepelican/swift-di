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
        APIClient()
    }
}
""", expandedSource: """
struct RootComponent {
    func apiClient() -> APIClient {
        APIClient()
    }

    @Sendable private static func __provide__apiClient(`self`: Self, components: [any Component]) -> APIClient {
        func `get`<I>(_ key: Key<I>) -> I {
            self.container.get(key, with: components)
        }
        let instance = { () -> APIClient in
            APIClient()
        }()
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

    @Sendable private static func __provide__urlSession(`self`: Self, components: [any Component]) -> URLSession {
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

    @Sendable private static func __provide__urlSession(`self`: Self, components: [any Component]) -> URLSession {
        func `get`<I>(_ key: Key<I>) -> I {
            self.container.get(key, with: components)
        }
        let instance = { () -> URLSession in
            .shared
        }()
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

    func testStoredLet() {
        // stored let
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.urlSession)
    let urlSession: URLSession
}
""", expandedSource: """
struct RootComponent {
    let urlSession: URLSession

    @Sendable private static func __provide__urlSession(`self`: Self, components: [any Component]) -> URLSession {
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

struct S {
    var foo: Int, bar: Int
}
