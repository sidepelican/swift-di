import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DIMacros: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        ComponentMacro.self,
        ProvidesMacro.self,
    ]
}
