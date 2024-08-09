import DI
import Foundation

extension AnyKey {
    static let urlSession = Key<URLSession>()
    static let client = Key<APIClient>()
}

struct DIRegistration<Component, T> {
    var key: Key<T>
    var provider: (Component, Container) -> T
}

@Component(root: true)
struct RootComponent: Sendable {
    init() {
        session = URLSession(configuration: .default)
        initContainer(parent: self)
    }

    func getValue<T>(_ key: Key<T>) -> T {
        switch key {
        case .urlSession: session as! T
        case .client: apiClient() as! T
        case .userRepository: userRepository() as! T
        case .imageRepository: imageRepository() as! T
        default:
            preconditionFailure("")
        }
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

    private mutating func initContainer2(parent: some DI.Component) {
        container = parent.container
        let s6client13RootComponent0C0fMm_3setfMu_ = container.setter(for: .client)
        s6client13RootComponent0C0fMm_3setfMu_(&container, __provide__client)
        let s6client13RootComponent0C0fMm_3setfMu0_ = container.setter(for: .imageRepository)
        s6client13RootComponent0C0fMm_3setfMu0_(&container, __provide__imageRepository)
        let s6client13RootComponent0C0fMm_3setfMu1_ = container.setter(for: .urlSession)
        s6client13RootComponent0C0fMm_3setfMu1_(&container, __provide__urlSession)
        let s6client13RootComponent0C0fMm_3setfMu2_ = container.setter(for: .userRepository)
        s6client13RootComponent0C0fMm_3setfMu2_(&container, __provide__userRepository)
    }

}

/**
    # 現状感じる課題
    - せっかく値型なのだからカジュアルに直接mutatingしてその結果を使って値を取り出したい
        - ex: rootComponent.configを書き換える
    - 優先度がほしい。テスト用として差し込んだコンポーネントは下層コンポーネントで上書きを拒否してほしい。

 */

func f() {
    let rootComponent = RootComponent()

    let userRepositoryRef = RootComponent.userRepository

    let appComponent = AppComponent(parent: rootComponent)
    let appComponentParent: any Component = rootComponent

//    appComponent.container.get(.userRepository)
    
    for component in [appComponent, appComponentParent] {
        guard let c = component as? RootComponent else {
            continue
        }
        userRepositoryRef(c)()
    }
}
