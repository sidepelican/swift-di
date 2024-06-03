import DI

let diRepository = Key<any Repository>()
let diEventLoop = Key<any EventLoop>()

@Component(root: true)
struct RootComponent {

    @Provides(diEventLoop)
    func eventLoop() -> any EventLoop {
        return .singleton
    }

    @Provides(diRepository)
    func repository() -> DatabaseRepository {
        DatabaseRepository(
            eventLoop: get(diEventLoop)
        )
    }
}
