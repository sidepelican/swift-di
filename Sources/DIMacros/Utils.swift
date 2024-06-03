import SwiftSyntax

func funcNameSafe(_ syntax: some CustomStringConvertible) -> String {
    return syntax.description.replacing(#/[\\\.]/#) { m in
        "_"
    }
}
