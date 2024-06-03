public struct VariantChecker<I> {
    @inlinable
    public init(_ key: DI.Key<I>) {
    }

    @inlinable
    public func callAsFunction(_ instance: I) -> Bool {
        return true
    }
}
