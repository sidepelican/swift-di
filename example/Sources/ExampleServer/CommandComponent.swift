import DI

@Component
struct CommandComponent: Sendable {
    func listUserCommand() -> ListUserCommand {
        .init(repository: get(.repository))
    }
}
