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

        var requiredKeys = Set<String>()
        var providingKeys = Set<String>()
        var hasInitDecl = false

        for member in structDecl.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                if let body = functionDecl.body {
                    requiredKeys.formUnion(findKeysUsingGet(in: body))
                }

                if let providesAttr = functionDecl.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.description == "Provides"
                }) {
                    if case .attribute(let providesAttr) = providesAttr {
                        if let key = extractKey(from: providesAttr) {
                            providingKeys.insert(key)
                        }
                    }
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self),
                      let computedProp = varDecl.bindings.first?.accessorBlock {
                requiredKeys.formUnion(findKeysUsingGet(in: computedProp))
            } else if let _ = member.decl.as(InitializerDeclSyntax.self) {
                hasInitDecl = true
            }
        }

        let missingKeys = requiredKeys.subtracting(providingKeys).sorted()
        if isRoot {
            guard missingKeys.isEmpty else {
                throw MessageError("root component must provide all required values. missing: \(missingKeys.joined(separator: ", "))")
            }
        }

        var result: [DeclSyntax] = []
        result.append("""
        static var requirements: Set<DI.AnyKey> {
            [\(raw: missingKeys.joined(separator: ", "))]
        }
        """)
        result.append("var container = DI.Container()")
        if !hasInitDecl {
            result.append(buildInitDecl(
                isRoot: isRoot,
                requiredKeys: requiredKeys,
                providingKeys: providingKeys
            ))
        }
        result.append(buildInitContainer(
            requiredKeys: requiredKeys,
            providingKeys: providingKeys
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
    isRoot: Bool,
    requiredKeys: Set<String>,
    providingKeys: Set<String>
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
    requiredKeys: Set<String>,
    providingKeys: Set<String>
) -> DeclSyntax {
    let assertExpr = requiredKeys.isEmpty ? "" : """
        assert(Self.requirements.subtracting(parent.container.keys).isEmpty)
        """ as ExprSyntax

    let provideSet = providingKeys
        .sorted()
        .map { "container.set(\(raw: $0), provide: __provide_\(raw: $0))" as CodeBlockItemSyntax }

    return """
    private mutating func initContainer(parent: some DI.Component) {
        \(assertExpr)
        container = parent.container
        \(CodeBlockItemListSyntax(provideSet))
    }
    """
}

private func extractKey(from attribute: AttributeSyntax) -> String? {
    guard let argument = attribute.arguments?.as(LabeledExprListSyntax.self)?.first,
          let keyIdentifier = argument.expression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
        return nil
    }
    return keyIdentifier
}

private class GetCallVisitor: SyntaxVisitor {
    var keys = Set<String>()
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if node.calledExpression.description.starts(with: "get"),
           let firstArg = node.arguments.first?.expression.as(DeclReferenceExprSyntax.self) {
            keys.insert(firstArg.baseName.text)
        }
        return .visitChildren
    }
}
private func findKeysUsingGet(in body: some SyntaxProtocol) -> Set<String> {
    let visitor = GetCallVisitor(viewMode: .fixedUp)
    visitor.walk(body)
    return visitor.keys
}
