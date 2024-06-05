import DI

@Component
struct CommandComponent {
    func listUserCommand() -> ListUserCommand {
        .init(repository: get(.repository))
    }
}
