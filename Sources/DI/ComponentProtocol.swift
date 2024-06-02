public protocol Component {
    var container: Container { get set }
}

extension Component {
    @inlinable
    func get<I>(_ key: (some Key<I>).Type) -> I {
        return container.get(key)
    }

    public func withContainer<R>(container: Container, _ operation: (Self) -> R) -> R {
        var copy = self
        copy.container = container
        return operation(copy)
    }
}
