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

    var container = DI.Container()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
    }
}

extension EmptyComponent: DI.Component {
}
""", macros: macros
        )
    }

    func testRootComponent() {
        assertMacroExpansion("""
@Component(root: true)
struct RootComponent {
}
""", expandedSource: """
struct RootComponent {

    var container = DI.Container()

    init() {
        initContainer(parent: self)
    }

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
    }
}

extension RootComponent: DI.Component {
}
""", macros: macros
        )
    }

    func testRootComponent_missingReqiurements() {
        assertMacroExpansion("""
@Component(root: true)
struct RootComponent {
    var foo: Int {
        return get(barKey) + 1
    }
}
""", expandedSource: """
struct RootComponent {
    var foo: Int {
        return get(barKey) + 1
    }
}

extension RootComponent: DI.Component {
}
""", diagnostics: [
    .init(message: "root component must provide all required values. missing: barKey", line: 1, column: 1),
], macros: macros
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

    func __provide_baseURLKey(container: DI.Container) -> URL {
        var copy = self
        copy.container = container
        return copy.baseURL()
    }

    func myRepository() -> MyRepository {
        MyRepository(
            apiClient: get(apiClientKey)
        )
    }

    static var requirements: Set<DI.AnyKey> {
        [apiClientKey, apiVersionKey]
    }

    var container = DI.Container()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        assert(Self.requirements.subtracting(parent.container.keys).isEmpty)
        container = parent.container
        container.set(baseURLKey, provide: __provide_baseURLKey)
    }
}

extension AnonymousComponent: DI.Component {
}
"""#, macros: macros
        )
    }


}
