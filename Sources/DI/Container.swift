public struct ComponentProvidingMetadata<C>: Sendable {
    public init() {
    }
    
    public var table: [AnyKey: any FunctionTableElement] = [:]

//    @inlinable
//    public mutating func set<I>(
//        for key: Key<I>,
//        _ provide: @escaping @Sendable (C) -> I
//    ) {
//        self.table[key] = FunctionDescriptor(ref: provide)
//    }

    @inlinable
    public func setter<I>(
        for key: Key<I>,
        priority: Priority
    ) -> (inout Self, @escaping @Sendable (C) -> I) -> () {
        return { `self`, provide in
            self.table[key] = ComponentFunctionElement(priority: priority, ref: provide)
        }
    }
}

public protocol FunctionTableElement: Sendable {
    associatedtype ComponentType
    var priority: Priority { get }
}

@usableFromInline struct ComponentFunctionElement<C, I>: FunctionTableElement {
    @usableFromInline init(priority: Priority, ref: @escaping @Sendable (C) -> I) {
        self.priority = priority
        self.ref = ref
    }
    @usableFromInline typealias ComponentType = C
    @usableFromInline var priority: Priority
    @usableFromInline var ref: @Sendable (C) -> I
}

@usableFromInline enum ValueTypeForFixedValueElement {}

@usableFromInline struct FixedValueElement<I>: @unchecked Sendable, FunctionTableElement {
    @usableFromInline init(priority: Priority, value: I) where I: Sendable {
        self.priority = priority
        self.value = value
    }
    @usableFromInline typealias ComponentType = ValueTypeForFixedValueElement
    @usableFromInline var priority: Priority
    @usableFromInline var value: I
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
    internal mutating func setFixed<Instance: Sendable>(
        _ key: Key<Instance>,
        priority: Priority,
        value: Instance
    ) {
        if let found = combinedMetadata[key] {
            if found.priority <= priority {
                combinedMetadata[key] = FixedValueElement(priority: priority, value: value)
            }
        } else {
            combinedMetadata[key] = FixedValueElement(priority: priority, value: value)
        }
    }

    @inlinable
    internal func get<Instance>(
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
                if E.ComponentType.self == C.self {
                    return (element as! ComponentFunctionElement<C, Instance>).ref(component)
                }
                return nil
            }
            for parent in components.reversed() {
                if let found = applyIfMatched(parent, element: element) {
                    return found
                }
            }

            if E.ComponentType.self == ValueTypeForFixedValueElement.self {
                return (element as! FixedValueElement<Instance>).value
            }
            preconditionFailure("Matched component not found. expected=\(E.ComponentType.self), components=\(components.map({ type(of: $0) }))")
        }
    }
}
