import DIMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ComponentMacroTests: XCTestCase {
    let macros: [String: Macro.Type] = [
        "Component": ComponentMacro.self,
        "Provides": ProvidesMacro.self,
    ]

    func testEmptyComponent() {
        assertMacroExpansion("""
@Component
struct EmptyComponent {
}
""", expandedSource: """
struct EmptyComponent {

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container: DI.Container

    init(parent: some DI.Component) {

        container = parent.container

    }
}

extension EmptyComponent: DI.Component {
}
""", macros: macros
        )
    }

    func testBasic() {
        assertMacroExpansion(#"""
@Component
struct AnonymousComponent {
    @Provides(baseURLKey)
    func baseURL() -> URL {
        URL(string: "https://foo.example.com/\(get(apiVersionKey))/")!
    }

    func myRepository() -> MyRepository {
        MyRepository(
            apiClient: get(apiClientKey)
        )
    }
}
"""#, expandedSource: #"""
struct AnonymousComponent {
    func baseURL() -> URL {
        URL(string: "https://foo.example.com/\(get(apiVersionKey))/")!
    }

    func __provide__baseURLKey(c: Container) -> URL {
        return withContainer(container: c) { `self` in
            return self.baseURL()
        }
    }

    func myRepository() -> MyRepository {
        MyRepository(
            apiClient: get(apiClientKey)
        )
    }

    static var requirements: Set<DI.AnyKey> {
        [apiClientKey, apiVersionKey]
    }

    var container: DI.Container

    init(parent: some DI.Component) {
        assert(Self.requirements.subtracting(parent.container.storage.keys).isEmpty)
        container = parent.container
        container.set(baseURLKey, provide: __provide__baseURLKey)
    }
}

extension AnonymousComponent: DI.Component {
}
"""#, macros: macros
        )
    }


}
