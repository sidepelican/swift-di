import SwiftDiagnostics

enum ComponentMacroDiagnostic: DiagnosticMessage, FixItMessage {
    case initContainerNotCalled
    case prefersContainer

    var severity: DiagnosticSeverity { .warning }

    @_implements(DiagnosticMessage, message)
    var diagnosticMessage: String {
        switch self {
        case .initContainerNotCalled:
            return "Call initContainer(parent:) at the end to complete the setup correctly."
        case .prefersContainer:
            return "Prefer retrieving the value from the container, as subcomponents may override it."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "DI", id: "Provides.\(self)")
    }

    @_implements(FixItMessage, message)
    var fixItMessage: String {
        switch self {
        case .initContainerNotCalled:
            return "call initContainer(parent:)"
        case .prefersContainer:
            return "use get(_:)"
        }
    }

    var fixItID: MessageID {
        diagnosticID
    }
}
