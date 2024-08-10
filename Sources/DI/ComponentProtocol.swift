public protocol Component: Sendable {
    var container: Container { get set }
    var parents: [any Component] { get set }
    static func buildMetadata() -> ComponentProvidingMetadata<Self>
    static var requirements: Set<AnyKey> { get }
}

extension Component {
    @inlinable
    public func get<I>(_ key: Key<I>) -> I {
        if let c = Components.current {
            return container.get(key, with: c)
        }
        let components = parents + CollectionOfOne<any Component>(self)
        return Components.dollarCurrent.withValue(components) {
            return container.get(key, with: components)
        }
    }

    @inlinable
    public func _get<I>(_ key: Key<I>, with components: [any Component]) -> I {
        return container.get(key, with: components)
    }

    public mutating func initContainer(parent: (any DI.Component)?) {
        if let parent {
            assertRequirements(Self.requirements, container: parent.container)
            container = parent.container
            parents = parent.parents + CollectionOfOne<any Component>(parent)
        }
        container.combine(metadata: Self.buildMetadata())
        for i in parents.indices {
            parents[i].container = container
        }
    }
}

@usableFromInline enum Components {
    @TaskLocal
    @usableFromInline static var current: [any Component]? = nil
    @usableFromInline static var dollarCurrent: TaskLocal<[any Component]?> {
        $current
    }
}

