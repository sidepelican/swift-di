public protocol Component: Sendable {
    var container: Container { get set }
    var parents: [any Component] { get set }
    static var provideMetadata: ComponentProvidingMetadata<Self> { get }
    static var requirements: Set<AnyKey> { get }
}

extension Component {
    @inlinable
    public func get<I>(_ key: Key<I>) -> I {
        let components = parents + CollectionOfOne<any Component>(self)
        return container.get(key, with: components)
    }

    public mutating func initContainer(parent: (any DI.Component)?) {
        if let parent {
            assertRequirements(Self.requirements, container: parent.container)
            container = parent.container
            parents = parent.parents + CollectionOfOne<any Component>(parent)
        }
        container.combine(metadata: Self.provideMetadata)
        for i in parents.indices {
            parents[i].container = container
        }
    }
}
