@inlinable
public func assertRequirements(
    _ requirements: Set<AnyKey>,
    container: Container,
    file: StaticString = #file,
    line: UInt = #line
) {
    assert(requirements.subtracting(container.keys).isEmpty, message(requirements, container), file: file, line: line)
}

@usableFromInline
func message(
    _ requirements: Set<AnyKey>,
    _ container: Container
) -> String {
    if container.keys.isEmpty {
        return "container is empty. Please call initContainer(parent:) at the end of init in the parent container."
    } else {
        return "keys not found in the container. missing: \(requirements.subtracting(container.keys))"
    }
}
