import SwiftDiagnostics

enum ComponentMacroDiagnostic: DiagnosticMessage, FixItMessage {
    case initContainerNotCalled
    case prefersContainer

    var severity: DiagnosticSeverity { .warning }

    @_implements(DiagnosticMessage, message)
    var diagnosticMessage: String {
        switch self {
        case .initContainerNotCalled:
            return "To complete the setup correctly, call initContainer(parent:) at the end."
        case .prefersContainer:
            return "Is is preffered to retrieve the value from container. Because subcomponents may override the value."
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
