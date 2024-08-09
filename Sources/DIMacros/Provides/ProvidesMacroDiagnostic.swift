import SwiftDiagnostics

enum ProvidesMacroDiagnostic: DiagnosticMessage, FixItMessage {
    var severity: DiagnosticSeverity { .warning }

    @_implements(DiagnosticMessage, message)
    var diagnosticMessage: String {
        switch self {
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "DI", id: "Provides.\(self)")
    }

    @_implements(FixItMessage, message)
    var fixItMessage: String {
        switch self {
        }
    }

    var fixItID: MessageID {
        diagnosticID
    }
}
