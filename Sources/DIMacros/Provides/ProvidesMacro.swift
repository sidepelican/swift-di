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
        if let functionDecl = declaration.as(FunctionDeclSyntax.self) {
            guard let type = functionDecl.signature.returnClause?.type else {
                throw MessageError("Expected a return type.")
            }
            guard functionDecl.signature.parameterClause.parameters.isEmpty else {
                throw MessageError("Provider function cannot have the arguments.")
            }
            returnType = type
            callExpr = "\(functionDecl.name.trimmed)()"
        } else if let varDecl = declaration.as(VariableDeclSyntax.self) {
            guard let binding = varDecl.bindings.first,
                  let type = binding.typeAnnotation?.type else {
                throw MessageError("Expected a type annotation.")
            }
            returnType = type
            callExpr = "\(binding.pattern)"
        } else {
            throw MessageError("@Provides should be added to the 'func' or 'var' or 'let'.")
        }

        let keyFuncName = funcNameSafe(keyIdentifier)

        var result: [DeclSyntax] = []
        result.append("""
        @Sendable private static func __provide_\(raw: keyFuncName)(`self`: Self) -> \(returnType.trimmed) {
            let instance = self.\(callExpr)
            assert({
                let check = DI.VariantChecker(\(raw: keyIdentifier))
                return check(instance)
            }())
            return instance
        }
        """)
        return result
    }
}
