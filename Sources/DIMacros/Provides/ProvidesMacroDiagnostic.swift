import SwiftDiagnostics

enum ProvidesMacroDiagnostic: DiagnosticMessage, FixItMessage {
    case plainVar

    var severity: DiagnosticSeverity { .warning }

    @_implements(DiagnosticMessage, message)
    var diagnosticMessage: String {
        switch self {
        case .plainVar:
            return "Attaching @Provides to a stored 'var' may cause unexpected behavior, because modifying it after the initContainer(parent:) call does not affect the container."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "DI", id: "Provides.\(self)")
    }

    @_implements(FixItMessage, message)
    var fixItMessage: String {
        switch self {
        case .plainVar:
            return "change 'var' to 'let'"
        }
    }

    var fixItID: MessageID {
        diagnosticID
    }
}
