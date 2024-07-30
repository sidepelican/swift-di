import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

internal struct FoundProvides {
    var key: ExtractedKey
    var callExpression: String
}

public struct ComponentMacro: MemberMacro, ExtensionMacro {

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
        var providings: [FoundProvides] = []
        var hasInitDecl = false

        for member in structDecl.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                if let body = functionDecl.body {
                    requiredKeys.formUnion(extractKeysUsedInGet(in: body))
                }
                if let key = extractAttributes(attributes: functionDecl.attributes) {
                    providings.append(.init(key: key, callExpression: "\(functionDecl.name)()"))
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self),
                      let binding = varDecl.bindings.first {
                if let computedProp = binding.accessorBlock {
                    requiredKeys.formUnion(extractKeysUsedInGet(in: computedProp))
                }
                if let key = extractAttributes(attributes: varDecl.attributes) {
                    providings.append(.init(key: key, callExpression: "\(binding.pattern)"))
                }
            } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                hasInitDecl = true
                let visitor = InitContainerCallVisitor(viewMode: .fixedUp)
                visitor.walk(initDecl)
                if !visitor.initContainerCalled {
                    if var body = initDecl.body {
                        let lastStmtLeadingTrivia = body.statements.last?.leadingTrivia
                        body.statements.append("\(lastStmtLeadingTrivia ?? "\n")initContainer(parent: \(raw: isRoot ? "self" : "parent"))")

                        context.diagnose(.init(
                            node: initDecl,
                            message: ComponentMacroDiagnostic.initContainerNotCalled,
                            fixIt: .replace(message: ComponentMacroDiagnostic.initContainerNotCalled, oldNode: initDecl.body!, newNode: body)
                        ))
                    }
                }
            }
        }

        let callArgumentsVisitor = CallArgumentsVisitor(providings: providings)
        callArgumentsVisitor.walk(structDecl.memberBlock)
        for d in callArgumentsVisitor.diagnostics {
            context.diagnose(d)
        }

        requiredKeys.subtract(providings.map(\.key))
        let requiredKeysSorted = requiredKeys.sorted()

        if isRoot && !requiredKeys.isEmpty {
            context.diagnose(.init(
                node: declaration,
                message: ComponentMacroDiagnostic.missingRequiredValues(keys: requiredKeysSorted.map(\.description))
            ))
        }

        var result: [any DeclSyntaxProtocol] = []
        if !requiredKeysSorted.isEmpty {
            result.append("""
            static var requirements: Set<DI.AnyKey> {
                [\(raw: requiredKeysSorted.map(\.description).joined(separator: ", "))]
            }
            """ as DeclSyntax)
        }
        result.append("\(declaration.modifiers)var container = DI.Container()" as DeclSyntax)
        if !hasInitDecl {
            result.append(buildInitDecl(
                isRoot: isRoot
            ).with(\.modifiers, declaration.modifiers))
        }
        result.append(buildInitContainer(
            requiredKeys: requiredKeysSorted,
            providingKeys: Set(providings.map(\.key)),
            in: context
        ))
        return result.map { DeclSyntax($0) }
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

private func extractAttributes(attributes: AttributeListSyntax) -> ExtractedKey? {
    if let providesAttr = attributes.first(where: {
        $0.as(AttributeSyntax.self)?.attributeName.description == "Provides"
    }) {
        if case .attribute(let providesAttr) = providesAttr {
            if let key = extractKey(from: providesAttr) {
                return key
            }
        }
    }
    return nil
}

private func buildInitDecl(
    isRoot: Bool
) -> InitializerDeclSyntax {
    if isRoot {
        return try! InitializerDeclSyntax("init()") {
            "initContainer(parent: self)"
        }
    } else {
        return try! InitializerDeclSyntax("init(parent: some DI.Component)") {
            "initContainer(parent: parent)"
        }
    }
}

private func buildInitContainer(
    requiredKeys: [ExtractedKey],
    providingKeys: Set<ExtractedKey>,
    in context: some MacroExpansionContext
) -> FunctionDeclSyntax {
    return try! FunctionDeclSyntax("private mutating func initContainer(parent: some DI.Component)") {
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
}

private class InitContainerCallVisitor: SyntaxVisitor {
    var initContainerCalled = false
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self),
           calledExpression.baseName.trimmed.description == "initContainer" {
            initContainerCalled = true
            return .skipChildren
        }
        return .visitChildren
    }
}

internal class CallArgumentsVisitor: SyntaxVisitor {
    init(providings: [FoundProvides]) {
        self.providings = providings
        super.init(viewMode: .fixedUp)
    }

    let providings: [FoundProvides]
    private(set) var diagnostics: [Diagnostic] = []

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        // avoid this diagnostic by wrapping the expr with ().
        if node.parent?.parent?.is(TupleExprSyntax.self) == true {
            return .skipChildren
        }

        let rawExprString = node.expression.description
        let exprString = if rawExprString.hasPrefix("self.") {
            String(rawExprString.dropFirst("self.".count))
        } else {
            rawExprString
        }

        if let providing = providings.first(where: {
            exprString == $0.callExpression || exprString.hasPrefix($0.callExpression + ".")
        }) {
            let newNode = rawExprString.replacingOccurrences(of: providing.callExpression, with: "get(\(providing.key))")
            
            diagnostics.append(
                .init(
                    node: node.expression,
                    message: ComponentMacroDiagnostic.prefersContainer,
                    fixIt: .replace(
                        message: ComponentMacroDiagnostic.prefersContainer,
                        oldNode: node.expression,
                        newNode: ExprSyntax(stringLiteral: newNode)
                    )
                )
            )

            return .skipChildren
        }
        return .visitChildren
    }
}
