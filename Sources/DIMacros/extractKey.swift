import SwiftSyntax

// eg: AnyKey.foo => .foo
// eg: .foo => .foo
// eg: foo => foo
// eg: DI.AnyKey.foo => .foo
// eg: MyKeys.foo => MyKeys.foo
// eg: MyModule.MyKeys.foo => MyModule.MyKeys.foo
struct ExtractedKey: Hashable, Comparable, CustomStringConvertible {
    var description: String

    init(_ syntax: ExprSyntax) {
        if let syntax = syntax.as(MemberAccessExprSyntax.self) {
            if let base = syntax.base {
                if let reference = base.as(DeclReferenceExprSyntax.self) {
                    if reference.baseName.description == "AnyKey" {
                        description = ".\(syntax.declName)"
                        return
                    }
                } else if let memberAccess = base.as(MemberAccessExprSyntax.self) {
                    if let base = memberAccess.base,
                       base.description == "DI",
                       memberAccess.declName.description == "AnyKey"
                    {
                        description = ".\(syntax.declName)"
                        return
                    }
                }
            } else {
                description = ".\(syntax.declName)"
                return
            }
        }
        description = "\(syntax.description)"
    }

    static func < (lhs: ExtractedKey, rhs: ExtractedKey) -> Bool {
        return lhs.description < rhs.description
    }
}

func extractKey(from attribute: AttributeSyntax) -> ExtractedKey? {
    guard let syntax = attribute.arguments?.as(LabeledExprListSyntax.self)?
        .first?.expression else {
        return nil
    }
    return ExtractedKey(syntax)
}

private class GetCallVisitor: SyntaxVisitor {
    var keys = [ExprSyntax]()

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self),
           calledExpression.baseName.trimmed.description == "get",
           let firstArg = node.arguments.first?.expression {
            keys.append(firstArg)
        }
        return .visitChildren
    }
}
func extractKeysUsedInGet(in body: some SyntaxProtocol) -> Set<ExtractedKey> {
    let visitor = GetCallVisitor(viewMode: .fixedUp)
    visitor.walk(body)
    return Set(visitor.keys.map {
        ExtractedKey($0)
    })
}
