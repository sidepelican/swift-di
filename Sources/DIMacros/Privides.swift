import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ProvidesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first,
              let keyIdentifier = argument.expression.as(DeclReferenceExprSyntax.self)?.baseName else {
            throw MessageError("Expected an identifier as an argument.")
        }

        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MessageError("Expected a function declaration.")
        }

        guard let returnType = functionDecl.signature.returnClause?.type else {
            throw MessageError("Expected a return type.")
        }

        return ["""
        func __provide_\(keyIdentifier)(c: DI.Container) -> \(returnType.trimmed) {
            return withContainer(container: c) { `self` in
                return self.\(functionDecl.name)()
            }
        }
        """]
    }
}
