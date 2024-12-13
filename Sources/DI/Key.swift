public class AnyKey: Hashable, @unchecked Sendable {
    public init() {
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: AnyKey, rhs: AnyKey) -> Bool {
        return type(of: lhs) == type(of: rhs)
            && ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

public final class Key<Instance>: AnyKey, @unchecked Sendable {
    public override init() {
    }
    
    public init(_ instanceType: Instance.Type) {
    }
}
