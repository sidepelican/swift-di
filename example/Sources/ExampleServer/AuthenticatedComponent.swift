import DI

@Component
struct AuthenticatedComponent {
    var user: User

    init(parent: some DI.Component, user: User) {
        self.init(parent: parent)
        self.user = user
    }

    func userController() -> UserController {
        UserController(
            user: user,
            repository: get(diRepository)
        )
    }
}
