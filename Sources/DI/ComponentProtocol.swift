public protocol Component: Sendable {
    var container: Container { get set }
    var parents: [any Component] { get set }
    static var providingMetadata: ComponentProvidingMetadata<Self> { get }
    static var requirements: Set<AnyKey> { get }
}

extension Component {
    @inlinable
    public func get<I>(_ key: Key<I>) -> I {
        let components = parents + CollectionOfOne<any Component>(self)
        return container.get(key, with: components)
    }

    @inlinable
    public mutating func override<I: Sendable>(
        _ key: Key<I>,
        value: I,
        priority: Priority = .default
    ) {
        for i in parents.indices {
            parents[i].container = Container() // avoid CoW
        }
        container.setFixed(key, priority: priority, value: value)
        for i in parents.indices {
            parents[i].container = container
        }
    }

    public mutating func initContainer(parent: (any DI.Component)?) {
        if let parent {
            assertRequirements(Self.requirements, container: parent.container)
            container = parent.container
            parents = parent.parents + CollectionOfOne<any Component>(parent)
        }
        container.combine(metadata: Self.providingMetadata)
        for i in parents.indices {
            parents[i].container = container
        }
    }
}
