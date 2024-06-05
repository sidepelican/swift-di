import DIMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ProvidesMacroTests: XCTestCase {
    let macros: [String: any Macro.Type] = [
        "Provides": ProvidesMacro.self,
    ]

    func testBasic() {
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
}
