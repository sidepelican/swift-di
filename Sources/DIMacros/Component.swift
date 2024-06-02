import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ComponentMacro: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MessageError("Expected a struct declaration.")
        }

        var requiredKeys = Set<String>()
        var providingKeys = Set<String>()

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
            }
        }

        return [
            """
            static var requirements: Set<DI.AnyKey> {
                [\(raw: requiredKeys.sorted().joined(separator: ", "))]
            }
            """,
            "var container: DI.Container",
            buildInitDecl(
                requiredKeys: requiredKeys,
                providingKeys: providingKeys
            ),
        ]
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

private func buildInitDecl(requiredKeys: Set<String>, providingKeys: Set<String>) -> DeclSyntax {
    let assertExpr = requiredKeys.isEmpty ? "" : """
    assert(Self.requirements.subtracting(parent.container.storage.keys).isEmpty)
    """ as ExprSyntax

    let provideSet = providingKeys
        .sorted()
        .map { "container.set(\(raw: $0), provide: __provide__\(raw: $0))" as CodeBlockItemSyntax }

    return """
    init(parent: some DI.Component) {
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
