import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ProvidesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argument: LabeledExprSyntax = node.arguments?.as(LabeledExprListSyntax.self)?.first else {
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
        @Sendable private func __provide_\(raw: funcNameSafe(keyIdentifier))(container: DI.Container) -> \(returnType.trimmed) {
            var copy = self
            copy.container = container
            let instance = copy.\(functionDecl.name.trimmed)()
            assert({
                let check = DI.VariantChecker(\(keyIdentifier))
                return check(instance)
            }())
            return instance
        }
        """]
    }
}
