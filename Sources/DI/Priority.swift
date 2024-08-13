public struct Priority: Comparable, Sendable {
    var rawValue: Int

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static var `default`: Priority {
        return .init(rawValue: 0)
    }

    public static var test: Priority {
        return .init(rawValue: 10)
    }

    public static func custom(_ value: Int) -> Priority {
        return .init(rawValue: value)
    }
}
