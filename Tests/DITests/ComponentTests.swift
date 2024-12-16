import DI
import XCTest

extension AnyKey {
    fileprivate static let name = Key<String>()
    fileprivate static let age = Key<Int>()
    fileprivate static let message = Key<String>()
    fileprivate static let getPatternA = Key<String>()
    fileprivate static let getPatternB = Key<String>()
    fileprivate static let getPatternC = Key<String>()
    fileprivate static let priorityTest = Key<Int>()
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

    @Provides(.priorityTest, priority: .custom(10))
    let priorityTest: Int = 10

    func getPriority() -> Int {
        get(.priorityTest)
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

    @Provides(.priorityTest, priority: .custom(20))
    let priorityTest: Int = 20

    func getPriority() -> Int {
        get(.priorityTest)
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

    @Provides(.priorityTest, priority: .custom(0))
    let priorityTest: Int = 0

    func getPriority() -> Int {
        get(.priorityTest)
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

    func testPriority() {
        let root = RootComponent()
        XCTAssertEqual(root.getPriority(), 10)
        let parent = root.parentComponent
        XCTAssertEqual(parent.getPriority(), 20)
        let child = parent.childComponent
        XCTAssertEqual(child.getPriority(), 20)
    }

    func testBind() {
        var parent = RootComponent().parentComponent
        XCTAssertEqual(parent.message, "I'm ParentComponent, age=42")

        // Override without/with priority
        parent.bind("Overridden", forKey: .name)
        parent.bind(-1, forKey: .age, priority: .custom(-1))
        XCTAssertEqual(parent.message, "I'm Overridden, age=42")
        parent.bind(99, forKey: .age)
        XCTAssertEqual(parent.message, "I'm Overridden, age=99")
    }

    func testBindWithInheritance() {
        var parent = RootComponent().parentComponent
        parent.bind("Overridden", forKey: .name)

        // The .name property becomes the child component’s one, but .age remains overridden because the child component does not provide the .age property.
        var child = parent.childComponent
        XCTAssertEqual(child.message(), "I'm ChildComponent, age=42")

        parent.bind("Overridden", forKey: .name, priority: .test)
        child = parent.childComponent
        XCTAssertEqual(child.message(), "I'm Overridden, age=42")
    }

    func testBindInChildAndUseInParent() {
        var child = RootComponent().parentComponent.childComponent
        XCTAssertEqual(child.message(), "I'm ChildComponent, age=42")
        child.bind("Overridden", forKey: .name)
        XCTAssertEqual(child.message(), "I'm Overridden, age=42")
    }

    enum GetWithoutProvideAnnotation {
        @Component(root: true) struct RootComponent {
            @Provides(.name) var name: String = "Root"

            var description: String {
                return get(.name)
            }

            @Provides(.message) func message() -> String {
                return description
            }
        }

        @Component struct ChildComponent {
            @Provides(.name) var name: String = "Child"

            func message() -> String {
                return get(.message)
            }
        }
    }

    func testGetWithoutProvideAnnotation() {
        let root = GetWithoutProvideAnnotation.RootComponent()
        let child = GetWithoutProvideAnnotation.ChildComponent(parent: root)
        XCTAssertEqual(child.message(), "Child")
    }
}
