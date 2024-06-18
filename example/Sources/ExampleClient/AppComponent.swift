import DI

extension AnyKey {
    static let imageRepository = Key<any ImageRepository>()
    static let userRepository = Key<any UserRepository>()
}

@Component
struct AppComponent: Sendable {
    func homeViewModel() -> HomeViewModel {
        HomeViewModel(
            imageRepository: get(.imageRepository)
        )
    }

    func detailViewModel() -> DetailViewModel {
        DetailViewModel(
            imageRepository: get(.imageRepository),
            userRepository: get(.userRepository)
        )
    }
}
