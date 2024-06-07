public protocol Component: Sendable {
    var container: Container { get set }
}

extension Component {
    @inlinable
    public func get<I>(_ key: some Key<I>) -> I {
        return container.get(key)
    }
}
