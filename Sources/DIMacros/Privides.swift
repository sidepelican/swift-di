import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ProvidesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first else {
            throw MessageError("Expected an identifier as an argument.")
        }
        let keyIdentifier = argument.expression

        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MessageError("@Provides should be added to the function declaration.")
        }

        guard let returnType = functionDecl.signature.returnClause?.type else {
            throw MessageError("Expected a return type.")
        }

        return ["""
        func __provide_\(keyIdentifier.trimmed)(container: DI.Container) -> \(returnType.trimmed) {
            var copy = self
            copy.container = container
            return copy.\(functionDecl.name.trimmed)()
        }
        """]
    }
}
