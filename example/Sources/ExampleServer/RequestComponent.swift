import DI

@Component
struct RequestComponent {
    var request: Request
    init(parent: some DI.Component, request: Request) {
        self.container = .init()
        self.request = request
        initContainer(parent: parent)
    }

    mutating func initContainer(parent: some DI.Component) {
        var container = parent.container
        container.set(diRepository, provide: __provide_diRepository)
        self.container = container
    }

    @Provides(diRepository)
    func repository() -> DatabaseRepository {
        DatabaseRepository(eventLoop: request.eventLoop)
    }

    func userManager() -> UserManager {
        UserManager(request: request)
    }

    func authenticatedComponent() async throws -> AuthenticatedComponent {
        guard let user = try await userManager().authenticate() else {
            throw Abort()
        }

        return AuthenticatedComponent(
            parent: self,
            user: user
        )
    }
}
