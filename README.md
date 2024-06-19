# Swift DI

Swift DI is a component-based DI (Dependency Injection) library designed specifically for Swift.

# Features

The DI container is implemented as a value type to take advantage of Swift's features.
No external executables are needed; it is implemented using standard Swift language features and macros.
By using only Swift features, the DI container can easily adapt to new versions of Swift, and users can also extend it to customize behaviors.
Multi-module compliance, Sendable conforming, and instance overwriting by lower components are supported.

# Getting Started

## Adding the dependency

To add a dependency on the package, declare it in your `Package.swift`:

```swift
.package(url: "https://github.com/sidepelican/swift-di.git", from: "1.0.0"),
```

and to your application target, add `DI` to your dependencies:

```swift
.product(name: "DI", package: "swift-di"),
```

# Using DI

In Swift DI, you need to explicitly prepare a key value for each instance. We recommend providing static `Key` properties as extensions of `AnyKey`.

```swift
import DI

extension AnyKey {
    // (1) Define DI keys.
    static let name = Key<String>()
    static let foo = Key<Foo>()
}

@Component(root: true)
struct RootComponent {
    // (2) Define value for the key.
    @Provides(.name)
    var name: String { "RootComponent" }

    @Provides(.foo)
    var foo: Foo {
        // (3) Get value using `get`.
        Foo(name: get(.name))
    }

    var childComponent: ChildComponent {
        ChildComponent(parent: self)
    }
}

@Component
struct ChildComponent {
    // (4) Child component can override parent component's key.
    @Provides(.name)
    var name: String { "ChildComponent" }

    func testFooName() {
        print(get(.foo)) // => Foo(name: "ChildComponent")
    }
}
```

# Frequently Asked Questions

### Q. How are singleton values defined per component?

Currently, there is no official method due to some challenges. However, it is easy to implement individually. Define the following class:

```swift
import Foundation

public final class SingletonStorage: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storage: [Int: Any] = [:]
    public init() {}
    public func callAsFunction<T>(key: Int = #line, _ make: @autoclosure () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        if let value = storage[key] {
            return value as! T
        }
        let value = make()
        storage[key] = value
        return value
    }
}
```

Then, you can easily use singletons by put this as a property of your Component.

```swift
@Component
struct SceneComponent {
    private let singleton = SingletonStorage()

    @Provides(.urlSession)
    var urlSession: URLSession {
        singleton(URLSession())
    }
}
```

### Q. I get a warning 'Conformance to 'Sendable' must occur ... for retroactive conformance'

This is a bug in the Swift compiler. It has been fixed but not yet released. As a workaround, explicitly add `Sendable` to your component.

### Q. I want to suppress the warning to use `get`

You can avoid the warning by wrapping the value in a tuple.

```swift
struct RootComponent: Sendable {
    init() {
        self.logger = Logger(label: "app")
        self.awsClient = AWSClient(
            logger: (logger) // avoid warning
        )
        initContainer(parent: self)
    }

    @Provides(.logger)
    let logger: Logger
    ...
}
```
