import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ComponentMacro: MemberMacro, ExtensionMacro {
    private struct Arguments {
        var root: Bool?
    }

    private static func extractArguments(from attribute: AttributeSyntax) throws -> Arguments {
        var result = Arguments()
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return result
        }
        for argument in arguments {
            if argument.label?.text == "root",
               let literal = argument.expression.as(BooleanLiteralExprSyntax.self) {
                switch literal.literal.text {
                case "true": result.root = true
                case "false": result.root = false
                default: throw MessageError("Unexpected literal.")
                }
            }
        }
        return result
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let argument = try extractArguments(from: node)
        let isRoot = argument.root ?? false
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MessageError("Expected a struct declaration.")
        }

        var requiredKeys = Set<ExtractedKey>()
        var providingKeys = Set<ExtractedKey>()
        var hasInitDecl = false

        func extractAttributes(attributes: AttributeListSyntax) {
            if let providesAttr = attributes.first(where: {
                $0.as(AttributeSyntax.self)?.attributeName.description == "Provides"
            }) {
                if case .attribute(let providesAttr) = providesAttr {
                    if let key = extractKey(from: providesAttr) {
                        providingKeys.insert(key)
                    }
                }
            }
        }

        for member in structDecl.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                if let body = functionDecl.body {
                    requiredKeys.formUnion(extractKeysUsedInGet(in: body))
                }
                extractAttributes(attributes: functionDecl.attributes)
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                if let computedProp = varDecl.bindings.first?.accessorBlock {
                    requiredKeys.formUnion(extractKeysUsedInGet(in: computedProp))
                }
                extractAttributes(attributes: varDecl.attributes)
            } else if let _ = member.decl.as(InitializerDeclSyntax.self) {
                hasInitDecl = true
            }
        }
        requiredKeys.subtract(providingKeys)
        let requiredKeysSorted = requiredKeys.sorted()

        if isRoot {
            guard requiredKeys.isEmpty else {
                throw MessageError("Root component must provide all required values. missing: \(requiredKeysSorted.map(\.description).joined(separator: ", "))")
            }
        }

        var result: [DeclSyntax] = []
        if !requiredKeysSorted.isEmpty {
            result.append("""
            static var requirements: Set<DI.AnyKey> {
                [\(raw: requiredKeysSorted.map(\.description).joined(separator: ", "))]
            }
            """)
        }
        result.append("var container = DI.Container()")
        if !hasInitDecl {
            result.append(buildInitDecl(
                isRoot: isRoot
            ))
        }
        result.append(buildInitContainer(
            requiredKeys: requiredKeysSorted,
            providingKeys: providingKeys,
            in: context
        ))
        return result
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let decl: DeclSyntax = """
        extension \(type.trimmed): DI.Component {
        }
        """
        return [
            decl.cast(ExtensionDeclSyntax.self)
        ]
    }
}

private func buildInitDecl(
    isRoot: Bool
) -> DeclSyntax {
    if isRoot {
        return """
        init() {
            initContainer(parent: self)
        }
        """
    } else {
        return """
        init(parent: some DI.Component) {
            initContainer(parent: parent)
        }
        """
    }
}

private func buildInitContainer(
    requiredKeys: [ExtractedKey],
    providingKeys: Set<ExtractedKey>,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    let function = try! FunctionDeclSyntax("private mutating func initContainer(parent: some DI.Component)") {
        if !requiredKeys.isEmpty {
            "assertRequirements(Self.requirements, container: parent.container)"
        }
        "container = parent.container"
        for key in providingKeys.sorted() {
            let setterName = context.makeUniqueName("set")
            "let \(setterName) = container.setter(for: \(raw: key))"
            "\(setterName)(&container, __provide_\(raw: funcNameSafe(key)))"
        }
    }

    return DeclSyntax(function)
}
