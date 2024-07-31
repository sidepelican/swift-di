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

    static var requirements: Set<DI.AnyKey> {
        [.bar]
    }

    var container = DI.Container()

    init() {
        initContainer(parent: self)
    }

    private mutating func initContainer(parent: some DI.Component) {
        assertRequirements(Self.requirements, container: parent.container)
        container = parent.container
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

    func testAllGetCallDetection() {
        assertMacroExpansion(
#"""
@Component
struct MyComponent {
    var manager: any Manager {
        AppManager(
            foo: get(.foo),
            bar: self.get(.bar),
            baz: container.get(.baz),
            qux: self.container.get(.qux)
        )
    }
}
"""#,
expandedSource: #"""
struct MyComponent {
    var manager: any Manager {
        AppManager(
            foo: get(.foo),
            bar: self.get(.bar),
            baz: container.get(.baz),
            qux: self.container.get(.qux)
        )
    }

    static var requirements: Set<DI.AnyKey> {
        [.bar, .baz, .foo, .qux]
    }

    var container = DI.Container()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        assertRequirements(Self.requirements, container: parent.container)
        container = parent.container
    }
}

extension MyComponent: DI.Component {
}
"""#, macros: ["Component": ComponentMacro.self]
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
        message: "Call initContainer(parent:) at the end to complete the setup correctly.",
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

    func testUseContainerDiagnostic() {
        assertMacroExpansion(
#"""
@Component
struct MyComponent {
    @Provides(.foo)
    let foo: Foo

    @Provides(.bar)
    func bar() -> Bar {
        Bar()
    }

    var manager: any Manager {
        AppManager(
            foo: foo,
            foo2: self.foo.two,
            bar: bar(),
            bar2: self.bar().two
        )
    }
}
"""#,
expandedSource: #"""
struct MyComponent {
    @Provides(.foo)
    let foo: Foo

    @Provides(.bar)
    func bar() -> Bar {
        Bar()
    }

    var manager: any Manager {
        AppManager(
            foo: foo,
            foo2: self.foo.two,
            bar: bar(),
            bar2: self.bar().two
        )
    }

    var container = DI.Container()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    private mutating func initContainer(parent: some DI.Component) {
        container = parent.container
        let __macro_local_3setfMu_ = container.setter(for: .bar)
        __macro_local_3setfMu_(&container, __provide__bar)
        let __macro_local_3setfMu0_ = container.setter(for: .foo)
        __macro_local_3setfMu0_(&container, __provide__foo)
    }
}

extension MyComponent: DI.Component {
}
"""#,
diagnostics: [
    .init(
        message: "Prefer retrieving the value from the container, as subcomponents may override it.",
        line: 13,
        column: 18,
        severity: .warning,
        fixIts: [
            .init(message: "use get(_:)"),
        ]
    ),
    .init(
        message: "Prefer retrieving the value from the container, as subcomponents may override it.",
        line: 14,
        column: 19,
        severity: .warning,
        fixIts: [
            .init(message: "use get(_:)"),
        ]
    ),
    .init(
        message: "Prefer retrieving the value from the container, as subcomponents may override it.",
        line: 15,
        column: 18,
        severity: .warning,
        fixIts: [
            .init(message: "use get(_:)"),
        ]
    ),
    .init(
        message: "Prefer retrieving the value from the container, as subcomponents may override it.",
        line: 16,
        column: 19,
        severity: .warning,
        fixIts: [
            .init(message: "use get(_:)"),
        ]
    ),
],
macros: ["Component": ComponentMacro.self]
        )
    }
}
