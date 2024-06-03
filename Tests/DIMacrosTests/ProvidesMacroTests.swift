import DIMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ProvidesMacroTests: XCTestCase {
    let macros: [String: Macro.Type] = [
        "Provides": ProvidesMacro.self,
    ]

    func testBasic() {
        assertMacroExpansion("""
struct RootComponent {
    @Provides(apiClientKey)
    func apiClient() -> APIClient {
        APIClient()
    }
}
""", expandedSource: """
struct RootComponent {
    func apiClient() -> APIClient {
        APIClient()
    }

    func __provide_apiClientKey(container: DI.Container) -> APIClient {
        var copy = self
        copy.container = container
        return copy.apiClient()
    }
}
""", macros: macros
        )
    }
}
