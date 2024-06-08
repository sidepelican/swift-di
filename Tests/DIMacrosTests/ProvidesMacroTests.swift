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

    @Sendable private func __provide__apiClient(container: DI.Container) -> APIClient {
        var copy = self
        copy.container = container
        let instance = copy.apiClient()
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

    func testProperty() {
        // stored var
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

    @Sendable private func __provide__urlSession(container: DI.Container) -> URLSession {
        var copy = self
        copy.container = container
        let instance = copy.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""",
diagnostics: [
    .init(
        message: "Attaching @Provides to a stored 'var' may cause unexpected behavior, because modifying it after the initContainer(parent:) call does not affect the container.",
        line: 2,
        column: 5,
        severity: .warning,
        fixIts: [.init(
            message: "change 'var' to 'let'"
        )]
    )
],
macros: macros
        )

        // computed var
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

    @Sendable private func __provide__urlSession(container: DI.Container) -> URLSession {
        var copy = self
        copy.container = container
        let instance = copy.urlSession
        assert({
            let check = DI.VariantChecker(.urlSession)
            return check(instance)
        }())
        return instance
    }
}
""", macros: macros
        )

        // stored let
        assertMacroExpansion("""
struct RootComponent {
    @Provides(.urlSession)
    let urlSession: URLSession
}
""", expandedSource: """
struct RootComponent {
    let urlSession: URLSession

    @Sendable private func __provide__urlSession(container: DI.Container) -> URLSession {
        var copy = self
        copy.container = container
        let instance = copy.urlSession
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
}
