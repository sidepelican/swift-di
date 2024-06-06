import DIMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ComponentMacroTests: XCTestCase {
    let macros: [String: any Macro.Type] = [
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
        return get(.bar) + 1
    }
}
""", expandedSource: """
struct RootComponent {
    var foo: Int {
        return get(.bar) + 1
    }
}

extension RootComponent: DI.Component {
}
""", diagnostics: [
    .init(message: "Root component must provide all required values. missing: .bar", line: 1, column: 1),
], macros: macros
        )
    }

    func testBasic() {
        assertMacroExpansion(#"""
@Component
struct AnonymousComponent {
    @Provides(baseURLKey)
    func baseURL() -> URL {
        URL(string: "https://foo.example.com/\(get(.apiVersion))/")!
    }

    func myRepository() -> MyRepository {
        MyRepository(
            apiClient: get(.apiClient)
        )
    }
}
"""#, expandedSource: #"""
struct AnonymousComponent {
    func baseURL() -> URL {
        URL(string: "https://foo.example.com/\(get(.apiVersion))/")!
    }

    @Sendable private func __provide_baseURLKey(container: DI.Container) -> URL {
        var copy = self
        copy.container = container
        let instance = copy.baseURL()
        assert({
            let check = DI.VariantChecker(baseURLKey)
            return check(instance)
        }())
        return instance
    }

    func myRepository() -> MyRepository {
        MyRepository(
            apiClient: get(.apiClient)
        )
    }

    static var requirements: Set<DI.AnyKey> {
        [.apiClient, .apiVersion]
    }

    var container = DI.Container()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        assertRequirements(Self.requirements, container: parent.container)
        container = parent.container
        let __macro_local_3setfMu_ = container.setter(for: baseURLKey)
        __macro_local_3setfMu_(&container, __provide_baseURLKey)
    }
}

extension AnonymousComponent: DI.Component {
}
"""#, macros: macros
        )
    }

    func testAutoInit() {
        // root component
        assertMacroExpansion(#"""
@Component(root: true)
public struct RootComponent {
}
"""#, expandedSource: #"""
public struct RootComponent {

    public var container = DI.Container()

    public init() {
        initContainer(parent: self)
    }

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
    }
}

extension RootComponent: DI.Component {
}
"""#, macros: macros
        )

        // sub component
        assertMacroExpansion(#"""
@Component
public struct MyComponent {
}
"""#, expandedSource: #"""
public struct MyComponent {

    public var container = DI.Container()

    public init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
    }
}

extension MyComponent: DI.Component {
}
"""#, macros: macros
        )
    }

    func testInitDiagnostic() {
        assertMacroExpansion(
#"""
@Component
struct MyComponent {
    init(parent: some DI.Component) {
    }
}
"""#,
expandedSource: #"""
struct MyComponent {
    init(parent: some DI.Component) {
    }

    var container = DI.Container()

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
    }
}

extension MyComponent: DI.Component {
}
"""#,
diagnostics: [
    .init(
        message: "To complete the setup correctly, call initContainer(parent:) at the end.",
        line: 3,
        column: 5,
        severity: .warning,
        fixIts: [
            .init(message: "call initContainer(parent:)"),
        ]
    )
],
macros: macros
        )
    }
}
