public struct ComponentProvidingMetadata<C>: Sendable {
    public init() {
    }
    
    public var table: [AnyKey: any FunctionTableElement] = [:]

//    @inlinable
//    public mutating func set<I>(
//        for key: Key<I>,
//        _ provide: @escaping @Sendable (C, [any Component]) -> I
//    ) {
//        self.table[key] = FunctionDescriptor(ref: provide)
//    }

    @inlinable
    public func setter<I>(
        for key: Key<I>,
        priority: Priority
    ) -> (inout Self, @escaping @Sendable (C, [any Component]) -> I) -> () {
        return { `self`, provide in
            self.table[key] = FunctionDescriptor(priority: priority, ref: provide)
        }
    }
}

public protocol FunctionTableElement: Sendable {
    associatedtype ValueType
    var priority: Priority { get }
}

@usableFromInline struct FunctionDescriptor<C, I>: FunctionTableElement {
    @usableFromInline init(priority: Priority, ref: @escaping @Sendable (C, [any Component]) -> I) {
        self.priority = priority
        self.ref = ref
    }
    @usableFromInline typealias ValueType = C
    @usableFromInline var priority: Priority
    @usableFromInline var ref: @Sendable (C, [any Component]) -> I
}

public struct Container: Sendable {
    @inlinable
    public init() {
    }
    
    @usableFromInline var combinedMetadata: [AnyKey: any FunctionTableElement] = [:]
    
    @inlinable
    public var keys: some (Collection<AnyKey> & Sequence<AnyKey>) {
        return combinedMetadata.keys
    }

    @inlinable
    public mutating func combine(metadata: ComponentProvidingMetadata<some Component>) {
        for (key, element) in metadata.table {
            if let found = combinedMetadata[key] {
                if found.priority <= element.priority {
                    combinedMetadata[key] = element
                }
            } else {
                combinedMetadata[key] = element
            }
        }
    }

    @inlinable
    public func get<Instance>(
        _ key: Key<Instance>,
        with components: [any Component]
    ) -> Instance {
        guard let element = combinedMetadata[key] else {
            if combinedMetadata.isEmpty {
                preconditionFailure("Container is empty. please call initContainer(parent: parent) at the end of init.")
            } else {
                preconditionFailure("\(key) is not found.")
            }
        }
        return openAndRun(element)

        func openAndRun<E: FunctionTableElement>(_ element: E) -> Instance {
            func applyIfMatched<C: Component>(_ component: C, element: E) -> Instance? {
                if C.self == E.ValueType.self {
                    return (element as! FunctionDescriptor<C, Instance>).ref(component, components)
                }
                return nil
            }
            for parent in components.reversed() {
                if let found = applyIfMatched(parent, element: element) {
                    return found
                }
            }
            preconditionFailure("Matched component not found. expected=\(E.ValueType.self), components=\(components.map({ type(of: $0) }))")
        }
    }
}
