import DI

@Component
struct AuthenticatedComponent {
    var user: User

    init(parent: some DI.Component, user: User) {
        self.user = user
        initContainer(parent: parent)
    }

    func userController() -> UserController {
        UserController(
            user: user,
            repository: get(.repository)
        )
    }
}
