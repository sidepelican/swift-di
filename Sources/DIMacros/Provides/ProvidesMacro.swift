import SwiftSyntax
import SwiftSyntaxMacros

public struct ProvidesMacro: PeerMacro {

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let argument = try Self.extractArguments(from: node)
        let keyIdentifier = argument.key.description

        let returnType: TypeSyntax
        let callExpr: TokenSyntax
        let getterBlock: CodeBlockItemListSyntax?
        if let functionDecl = declaration.as(FunctionDeclSyntax.self) {
            guard let type = functionDecl.signature.returnClause?.type else {
                throw MessageError("Expected a return type.")
            }
            guard functionDecl.signature.parameterClause.parameters.isEmpty else {
                throw MessageError("Provider function cannot have the arguments.")
            }
            returnType = type
            callExpr = "\(functionDecl.name.trimmed)()"
            getterBlock = functionDecl.body?.statements
        } else if let varDecl = declaration.as(VariableDeclSyntax.self) {
            guard let binding = varDecl.bindings.first,
                  let type = binding.typeAnnotation?.type else {
                throw MessageError("Expected a type annotation.")
            }
            returnType = type
            callExpr = "\(binding.pattern)"
            getterBlock = binding.accessorBlock?.accessors.getter
        } else {
            throw MessageError("@Provides should be added to the 'func' or 'var' or 'let'.")
        }

        let f = try FunctionDeclSyntax("@Sendable private static func __provide_\(raw: funcNameSafe(keyIdentifier))(`self`: Self, components: [any Component]) -> \(returnType.trimmed)") {
            if let getterBlock {
                """
                func `get`<I>(_ key: Key<I>) -> I {
                    self.container.get(key, with: components)
                }
                """
                """
                let instance = { () -> \(returnType.trimmed) in
                    \(SelfGetRewriter().visit(getterBlock).trimmed)
                }()
                """
            } else {
                "let instance = self.\(callExpr)"
            }
            """
            assert({
                let check = DI.VariantChecker(\(raw: keyIdentifier))
                return check(instance)
            }())
            """
            "return instance"
        }
        return [DeclSyntax(f)]
    }
}

extension AccessorBlockSyntax.Accessors {
    var `getter`: CodeBlockItemListSyntax? {
        switch self {
        case .getter(let syntax):
            return syntax
        case .accessors(let list):
            return list.first { decl in
                decl.accessorSpecifier.tokenKind == .keyword(.get)
            }?.body?.statements
        }
    }
}

private class SelfGetRewriter: SyntaxRewriter {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        if node.calledExpression.trimmedDescription == "self.get" {
            var node = node
            node.calledExpression = ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier("get"))
                    .with(\.leadingTrivia, node.calledExpression.leadingTrivia)
            )
            return ExprSyntax(node)
        }
        return super.visit(node)
    }
}
