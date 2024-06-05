import DI

extension AnyKey {
    static let eventLoop = Key<any EventLoop>()
    static let repository = Key<any Repository>()
}

@Component(root: true)
struct RootComponent {
    @Provides(.eventLoop)
    func eventLoop() -> any EventLoop {
        return .singleton
    }

    @Provides(.repository)
    func repository() -> DatabaseRepository {
        DatabaseRepository(
            eventLoop: get(.eventLoop)
        )
    }

    func requestComponent(request: Request) -> RequestComponent {
        RequestComponent(parent: self, request: request)
    }

    func commandComponent() -> CommandComponent{
        .init(parent: self)
    }
}
