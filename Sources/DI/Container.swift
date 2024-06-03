public struct Container: Sendable {
    public typealias Provider<I> = (Container) -> I

    @usableFromInline var storage: [ObjectIdentifier: any Sendable] = [:]

    @inlinable
    public init() {
    }

    @inlinable
    public func get<I>(_ key: (some Key<I>).Type) -> I {
        return getProvider(key)(self)
    }

    @inlinable
    public func getProvider<I>(
        _ key: (some Key<I>).Type
    ) -> Provider<I> {
        return storage[ObjectIdentifier(key)] as! Provider<I>
    }

    @inlinable
    public mutating func set<I>(
        _ key: (some Key<I>).Type,
        provide: @escaping Provider<I>
    ) {
        storage[ObjectIdentifier(key)] = provide
    }
}
