public struct Container: Sendable {
    public typealias Provider<I> = (Container) -> I

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
        return getProvider(key)(self)
    }

    @inlinable
    public func getProvider<I>(
        _ key: some Key<I>
    ) -> Provider<I> {
        return storage[key] as! Provider<I>
    }

    @inlinable
    public mutating func set<I>(
        _ key: some Key<I>,
        provide: @escaping Provider<I>
    ) {
        storage[key] = provide
    }
}
