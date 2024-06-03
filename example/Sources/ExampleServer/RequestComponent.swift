import DI

@Component
struct RequestComponent {
    var request: Request
    init(parent: some DI.Component, request: Request) {
        self.request = request
        initContainer(parent: parent)
    }

    @Provides(.eventLoop)
    func eventLoop() -> any EventLoop {
        request.eventLoop
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
