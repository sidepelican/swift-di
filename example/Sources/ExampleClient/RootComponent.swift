import DI
import Foundation

extension AnyKey {
    static let urlSession = Key<URLSession>()
    static let client = Key<APIClient>()
}

@Component(root: true)
struct RootComponent: Sendable {
    init() {
        session = URLSession(configuration: .default)
        initContainer(parent: self)
    }

    @Provides(.urlSession)
    let session: URLSession

    @Provides(.client)
    func apiClient() -> APIClient {
        APIClient(
            session: get(.urlSession)
        )
    }

    @Provides(.userRepository)
    func userRepository() -> some UserRepository {
        APIUserRepository(
            apiClient: get(.client)
        )
    }

    @Provides(DI.AnyKey.imageRepository)
    func imageRepository() -> some ImageRepository {
        NetworkImageRepository(
            urlSession: get(AnyKey.urlSession)
        )
    }

    func appComponent() -> AppComponent {
        AppComponent(parent: self)
    }
}
