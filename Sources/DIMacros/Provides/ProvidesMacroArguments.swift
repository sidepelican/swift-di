import SwiftSyntax

extension ProvidesMacro {
    struct Arguments {
        var key: ExtractedKey
    }

    static func extractArguments(from attribute: AttributeSyntax) throws -> Arguments {
        guard let key = extractKey(from: attribute) else {
            throw MessageError("Extract argument failed.")
        }
        return Arguments(key: key)
    }
}
