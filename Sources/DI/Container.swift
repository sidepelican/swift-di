public struct Container: Sendable {
    public typealias Provider<I> = @Sendable (Container) -> I

    @usableFromInline var storage: [AnyKey: any Sendable]

    @inlinable
    public var keys: [AnyKey: any Sendable].Keys {
        return storage.keys
    }

    @inlinable
    public init() {
        storage = [:]
    }

    @inlinable
    public func get<I>(_ key: some Key<I>) -> I {
        guard let anyProvider = storage[key] else {
            if storage.isEmpty {
                fatalError("container is empty. please call initContainer(parent: parent) at the end of init.")
            } else {
                fatalError("\(key) is not found.")
            }
        }
        return (anyProvider as! Provider<I>)(self)
    }

    @inlinable
    public mutating func set<I>(
        _ key: some Key<I>,
        provide: @escaping Provider<I>
    ) {
        storage[key] = provide
    }

    @inlinable
    public func setter<I>(
        for key: some Key<I>
    ) -> (inout Self, @escaping Provider<I>) -> () {
        return { `self`, provide in
            self.storage[key] = provide
        }
    }
}
