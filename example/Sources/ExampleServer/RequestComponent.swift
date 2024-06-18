import DI

@Component
struct RequestComponent: Sendable {
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
        UserManager(
            request: request,
            repository: get(.repository)
        )
    }
}
