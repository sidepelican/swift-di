import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ProvidesMacroDiagnostic: DiagnosticMessage, FixItMessage {
    case plainVar

    var message: String {
        switch self {
        case .plainVar:
            return "Attaching @Provides to a stored 'var' may cause unexpected behavior, because modifying it after the initContainer(parent:) call does not affect the container."
        }
    }

    var severity: DiagnosticSeverity { .warning}

    var diagnosticID: MessageID {
        MessageID(domain: "DI", id: "Provides.\(self)")
    }

    var fixItID: MessageID {
        diagnosticID
    }
}

public struct ProvidesMacro: PeerMacro {
    private struct Arguments {
        var key: ExtractedKey
    }

    private static func extractArguments(from attribute: AttributeSyntax) throws -> Arguments {
        guard let key = extractKey(from: attribute) else {
            throw MessageError("Extract argument failed.")
        }
        return Arguments(key: key)
    }

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
            returnType = type
            callExpr = "\(functionDecl.name.trimmed)()"
        } else if let varDecl = declaration.as(VariableDeclSyntax.self) {
            // TODO: enforce 'let' or get only 'var'.
            guard let binding = varDecl.bindings.first,
                  let type = binding.typeAnnotation?.type else {
                throw MessageError("Expected a return type.")
            }
            if varDecl.bindingSpecifier.tokenKind == .keyword(.var) {
                if binding.accessorBlock == nil {
                    context.diagnose(.init(
                        node: declaration,
                        message: ProvidesMacroDiagnostic.plainVar,
                        fixIt: .replace(
                            message: ProvidesMacroDiagnostic.plainVar,
                            oldNode: varDecl.bindingSpecifier,
                            newNode: TokenSyntax(.keyword(.let), presence: .present)
                        )
                    ))
                }
            }
            returnType = type
            callExpr = "\(binding.pattern)"
        } else {
            throw MessageError("@Provides should be added to the 'func' or 'var' or 'let'.")
        }

        return ["""
        @Sendable private func __provide_\(raw: funcNameSafe(keyIdentifier))(container: DI.Container) -> \(returnType.trimmed) {
            var copy = self
            copy.container = container
            let instance = copy.\(callExpr)
            assert({
                let check = DI.VariantChecker(\(raw: keyIdentifier))
                return check(instance)
            }())
            return instance
        }
        """]
    }
}
