import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DIMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
        ProvidesMacro.self,
    ]
}
