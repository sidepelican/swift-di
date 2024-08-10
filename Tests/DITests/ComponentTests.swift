import DI
import XCTest

extension AnyKey {
    fileprivate static let name = Key<String>()
    fileprivate static let age = Key<Int>()
    fileprivate static let message = Key<String>()
    fileprivate static let getPatternA = Key<String>()
    fileprivate static let getPatternB = Key<String>()
    fileprivate static let getPatternC = Key<String>()
}

@Component(root: true)
fileprivate struct RootComponent: Sendable {
    @Provides(.name)
    var name: String {
        "RootComponent"
    }

    @Provides(.age)
    func age() -> Int {
        42
    }

    var parentComponent: ParentComponent {
        ParentComponent(parent: self)
    }
}

@Component
fileprivate struct ParentComponent: Sendable {
    @Provides(.name)
    var name: String {
        "ParentComponent"
    }

    @Provides(.message)
    var message: String {
        "I'm \(get(.name)), age=\(get(.age))"
    }

    @Provides(.getPatternA)
    var getPatternA: String {
        self.get(.name) + get(.name)
    }

    @Provides(.getPatternB)
    var getPatternB: String {
        get {
            "\(get(.name))\(self.get(.name))"
        }
    }

    @Provides(.getPatternC)
    func getPatternC() -> String {
        return [
            self.get(.name),
            get(.name),
        ].joined()
    }

    var childComponent: ChildComponent {
        ChildComponent(parent: self)
    }
}

@Component
fileprivate struct ChildComponent: Sendable {
    @Provides(.name)
    var name: String = "ChildComponent"

    func message() -> String {
        get(.message)
    }

    func getPatterns() -> (String, String, String) {
        (get(.getPatternA), get(.getPatternB), get(.getPatternC))
    }
}

final class ComponentTests: XCTestCase {
    func testInheritanceAndOverrride() {
        let root = RootComponent()
        let parent = root.parentComponent
        XCTAssertEqual(parent.message, "I'm ParentComponent, age=42")
        let child = parent.childComponent
        XCTAssertEqual(child.message(), "I'm ChildComponent, age=42")
    }

    func testMutateSelf() {
        var child = RootComponent().parentComponent.childComponent
        XCTAssertEqual(child.message(), "I'm ChildComponent, age=42")

        child.name = "Foo"
        XCTAssertEqual(child.message(), "I'm Foo, age=42")
    }

    func testGetPatterns() {
        var child = RootComponent().parentComponent.childComponent
        child.name = "<>"
        let (a, b, c) = child.getPatterns()
        XCTAssertEqual(a, "<><>")
        XCTAssertEqual(b, "<><>")
        XCTAssertEqual(c, "<><>")
    }
}
