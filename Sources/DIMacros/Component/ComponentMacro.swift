import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

internal struct FoundProvides {
    var arguments: ProvidesMacroArguments
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
                if let arguments = extractProvides(attributes: functionDecl.attributes) {
                    providings.append(.init(arguments: arguments, callExpression: "\(functionDecl.name)()"))
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self),
                      let binding = varDecl.bindings.first {
                if let computedProp = binding.accessorBlock {
                    requiredKeys.formUnion(extractKeysUsedInGet(in: computedProp))
                }
                if let arguments = extractProvides(attributes: varDecl.attributes) {
                    providings.append(.init(arguments: arguments, callExpression: "\(binding.pattern)"))
                }
            } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                hasInitDecl = true
                let visitor = InitContainerCallVisitor(viewMode: .fixedUp)
                visitor.walk(initDecl)
                if !visitor.initContainerCalled {
                    if var body = initDecl.body {
                        let lastStmtLeadingTrivia = body.statements.last?.leadingTrivia
                        body.statements.append("\(lastStmtLeadingTrivia ?? "\n")initContainer(parent: \(raw: isRoot ? "nil" : "parent"))")

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

        requiredKeys.subtract(providings.map(\.arguments.key))
        let requiredKeysSorted = requiredKeys.sorted()

        if isRoot && !requiredKeys.isEmpty {
            context.diagnose(.init(
                node: declaration,
                message: ComponentMacroDiagnostic.missingRequiredValues(keys: requiredKeysSorted.map(\.description))
            ))
        }

        var result: [any DeclSyntaxProtocol] = []
        result.append("""
        static var requirements: Set<DI.AnyKey> {
            [\(raw: requiredKeysSorted.map(\.description).joined(separator: ", "))]
        }
        """ as DeclSyntax)
        result.append("\(declaration.modifiers)var container = DI.Container()" as DeclSyntax)
        result.append("\(declaration.modifiers)var parents = [any DI.Component]()" as DeclSyntax)
        if !hasInitDecl {
            result.append(buildInitDecl(
                isRoot: isRoot
            ).with(\.modifiers, declaration.modifiers))
        }
        result.append(buildBuildMetadata(
            modifiers: declaration.modifiers,
            requiredKeys: requiredKeysSorted,
            providings: providings.map(\.arguments),
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

internal struct ProvidesMacroArguments {
    var key: ExtractedKey
    var priority: ExprSyntax?
}

private func extractProvides(attributes: AttributeListSyntax) -> ProvidesMacroArguments? {
    if let providesAttr = attributes.first(where: {
        $0.as(AttributeSyntax.self)?.attributeName.description == "Provides"
    }) {
        if case .attribute(let providesAttr) = providesAttr {
            if let key = extractKey(from: providesAttr) {
                if let syntaxList = providesAttr.arguments?.as(LabeledExprListSyntax.self) {
                    var itr = syntaxList.makeIterator()
                    let _ = itr.next()
                    let second = itr.next()
                    if let second, second.label?.trimmedDescription == "priority" {
                        return ProvidesMacroArguments(key: key, priority: second.expression)
                    }
                }
                return ProvidesMacroArguments(key: key)
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
            "initContainer(parent: nil)"
        }
    } else {
        return try! InitializerDeclSyntax("init(parent: some DI.Component)") {
            "initContainer(parent: parent)"
        }
    }
}

private func buildBuildMetadata(
    modifiers: DeclModifierListSyntax,
    requiredKeys: [ExtractedKey],
    providings: [ProvidesMacroArguments],
    in context: some MacroExpansionContext
) -> some DeclSyntaxProtocol {
    if providings.isEmpty {
        return ("""
        \(modifiers)static var providingMetadata: ComponentProvidingMetadata<Self> {
            return ComponentProvidingMetadata<Self>()
        }
        """ as DeclSyntax).cast(VariableDeclSyntax.self)
    } else {
        let c = ClosureExprSyntax {
            "var metadata = ComponentProvidingMetadata<Self>()"
            for providing in providings {
                let setterName = context.makeUniqueName("set")
                "let \(setterName) = metadata.setter(for: \(raw: providing.key), priority: \(raw: providing.priority ?? ".default"))"
                "\(setterName)(&metadata, __provide_\(raw: funcNameSafe(providing.key)))"
            }
            "return metadata"
        }

        var modifiers = modifiers
        modifiers.append(.init(name: .keyword(.static)))
        return VariableDeclSyntax(modifiers: modifiers, bindingSpecifier: .keyword(.let)) {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: "providingMetadata"),
                typeAnnotation: TypeAnnotationSyntax(type: "ComponentProvidingMetadata<Self>" as TypeSyntax),
                initializer: .init(value: FunctionCallExprSyntax(callee: c))
            )
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
            let newNode = rawExprString.replacingOccurrences(of: providing.callExpression, with: "get(\(providing.arguments.key))")
            
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
