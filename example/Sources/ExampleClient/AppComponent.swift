import DI

extension AnyKey {
    static let imageRepository = Key<any ImageRepository>()
    static let userRepository = Key<any UserRepository>()
}

@Component
struct AppComponent {
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


struct Foo {}
struct Bar {}
protocol Manager {}
struct AppManager: Manager {
    var foo: Foo
    var bar: Bar
}
extension AnyKey {
    static let foo = Key<Foo>()
    static let bar = Key<Bar>()
}

@Component
struct MyComponent {
    @Provides(.foo)
    let foo: Foo

    @Provides(.bar)
    func bar() -> Bar {
        Bar()
    }

    var manager: any Manager {
        AppManager(
            foo: get(.foo),
            bar: get(.bar)
        )
    }
}
