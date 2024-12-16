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

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    init() {
        initContainer(parent: nil)
    }

    static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    var parents = [any DI.Component]()

    init() {
        initContainer(parent: nil)
    }

    static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    @Sendable private static func __provide_baseURLKey(`self`: Self) -> URL {
        let instance = self.baseURL()
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

    var parents = [any DI.Component]()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    static let providingMetadata: ComponentProvidingMetadata<Self> = {
        var metadata = ComponentProvidingMetadata<Self>()
        let __macro_local_3setfMu_ = metadata.setter(for: baseURLKey, priority: .default)
        __macro_local_3setfMu_(&metadata, __provide_baseURLKey)
        return metadata
    }()
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
    var repository: any Repository {
        self.get(.repository)
    }

    func manager() -> any Manager {
        return AppManager(
            foo: get(.foo),
            bar: self.get(.bar)
        )
    }
}
"""#,
expandedSource: #"""
struct MyComponent {
    var repository: any Repository {
        self.get(.repository)
    }

    func manager() -> any Manager {
        return AppManager(
            foo: get(.foo),
            bar: self.get(.bar)
        )
    }

    static var requirements: Set<DI.AnyKey> {
        [.bar, .foo, .repository]
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    public static var requirements: Set<DI.AnyKey> {
        []
    }

    public var container = DI.Container()

    public var parents = [any DI.Component]()

    public init() {
        initContainer(parent: nil)
    }

    public static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    public static var requirements: Set<DI.AnyKey> {
        []
    }

    public var container = DI.Container()

    public var parents = [any DI.Component]()

    public init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    public static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    static var providingMetadata: ComponentProvidingMetadata<Self> {
        return ComponentProvidingMetadata<Self>()
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

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    static let providingMetadata: ComponentProvidingMetadata<Self> = {
        var metadata = ComponentProvidingMetadata<Self>()
        let __macro_local_3setfMu_ = metadata.setter(for: .foo, priority: .default)
        __macro_local_3setfMu_(&metadata, __provide__foo)
        let __macro_local_3setfMu0_ = metadata.setter(for: .bar, priority: .default)
        __macro_local_3setfMu0_(&metadata, __provide__bar)
        return metadata
    }()
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

    func testPriority() throws {
        assertMacroExpansion(
#"""
@Component
struct MyComponent {
    @Provides(.foo, priority: .test)
    let foo: Foo

    @Provides(.bar, priority: .custom(2))
    func bar() -> Bar {
        Bar()
    }
}
"""#,
expandedSource: #"""
struct MyComponent {
    @Provides(.foo, priority: .test)
    let foo: Foo

    @Provides(.bar, priority: .custom(2))
    func bar() -> Bar {
        Bar()
    }

    static var requirements: Set<DI.AnyKey> {
        []
    }

    var container = DI.Container()

    var parents = [any DI.Component]()

    init(parent: some DI.Component) {
        initContainer(parent: parent)
    }

    static let providingMetadata: ComponentProvidingMetadata<Self> = {
        var metadata = ComponentProvidingMetadata<Self>()
        let __macro_local_3setfMu_ = metadata.setter(for: .foo, priority: .test)
        __macro_local_3setfMu_(&metadata, __provide__foo)
        let __macro_local_3setfMu0_ = metadata.setter(for: .bar, priority: .custom(2))
        __macro_local_3setfMu0_(&metadata, __provide__bar)
        return metadata
    }()
}

extension MyComponent: DI.Component {
}
"""#,
macros: ["Component": ComponentMacro.self]
        )
    }
}
