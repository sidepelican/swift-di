public struct ComponentProvidingMetadata<C>: Sendable {
    public init() {
    }
    
    public var table: [AnyKey: any WitnessTableElement] = [:]

//    @inlinable
//    public mutating func set<I>(
//        for key: Key<I>,
//        _ provide: @escaping @Sendable (C) -> I
//    ) {
//        self.table[key] = FunctionDescriptor(ref: provide)
//    }

    @inlinable
    public func setter<I>(
        for key: Key<I>
    ) -> (inout Self, @escaping @Sendable (C, [any Component]) -> I) -> () {
        return { `self`, provide in
            self.table[key] = FunctionDescriptor(ref: provide)
        }
    }
}

public protocol WitnessTableElement: Sendable {
    associatedtype ValueType
}

@usableFromInline struct FunctionDescriptor<C, I>: WitnessTableElement {
    @usableFromInline init(ref: @escaping @Sendable (C, [any Component]) -> I) {
        self.ref = ref
    }
    @usableFromInline typealias ValueType = C
    @usableFromInline var ref: @Sendable (C, [any Component]) -> I
}

public struct Container: Sendable {
    @inlinable
    public init() {
    }
    
    @usableFromInline var combinedMetadata: [AnyKey: any WitnessTableElement] = [:]
    
    @inlinable
    public var keys: some (Collection<AnyKey> & Sequence<AnyKey>) {
        return combinedMetadata.keys
    }

    @inlinable
    public mutating func combine(metadata: ComponentProvidingMetadata<some Component>) {
        for (key, function) in metadata.table {
            combinedMetadata[key] = function
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

        func openAndRun<E: WitnessTableElement>(_ element: E) -> Instance {
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
