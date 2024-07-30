import SwiftDiagnostics

enum ComponentMacroDiagnostic: DiagnosticMessage, FixItMessage {
    case initContainerNotCalled
    case prefersContainer
    case missingRequiredValues(keys: [String])

    var severity: DiagnosticSeverity {
        switch self {
        case .initContainerNotCalled, .prefersContainer:
            return .warning
        case .missingRequiredValues:
            return .error
        }
    }

    @_implements(DiagnosticMessage, message)
    var diagnosticMessage: String {
        switch self {
        case .initContainerNotCalled:
            return "Call initContainer(parent:) at the end to complete the setup correctly."
        case .prefersContainer:
            return "Prefer retrieving the value from the container, as subcomponents may override it."
        case .missingRequiredValues(let keys):
            return "Root component must provide all required values. missing: \(keys.joined(separator: ", "))"
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
        case .missingRequiredValues:
            fatalError("not fixit")
        }
    }

    var fixItID: MessageID {
        diagnosticID
    }
}
