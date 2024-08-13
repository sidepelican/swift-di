@attached(
    member,
    names:
        named(requirements),
    named(container),
    named(parents),
    named(providingMetadata),
    named(init(parent:)),
    named(init())
)
@attached(
    extension,
    conformances: Component
)
public macro Component(root: Bool? = nil) = #externalMacro(module: "DIMacros", type: "ComponentMacro")

@attached(
    peer,
    names: arbitrary
)
public macro Provides<I>(
    _ key: Key<I>,
    priority: Priority = .default
) = #externalMacro(module: "DIMacros", type: "ProvidesMacro")
