import SwiftUI

extension EnvironmentValues {
    struct AppComponentKey: EnvironmentKey {
        static var defaultValue: AppComponent? {
            nil
        }
    }
    var appComponent: AppComponent? {
        get { self[AppComponentKey.self] }
        set { self[AppComponentKey.self] = newValue }
    }
}

@main
struct MyApp: App {
    var rootComponent = RootComponent()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: rootComponent.appComponent().homeViewModel())
                .environment(\.appComponent, rootComponent.appComponent())
        }
    }
}

@Observable
class HomeViewModel {
    init(imageRepository: any ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    let imageRepository: any ImageRepository
}

struct HomeView: View {
    @Environment(\.appComponent) var appComponent
    var viewModel: HomeViewModel
    @State var present: Bool = false

    var body: some View {
        Button("Open Detail") {
            present = true
        }
        .sheet(isPresented: $present, onDismiss: nil) {
            DetailView(
                viewModel: appComponent!.detailViewModel()
            )
        }
    }
}

@Observable
class DetailViewModel {
    init(
        imageRepository: any ImageRepository,
        userRepository: any UserRepository
    ) {
        self.imageRepository = imageRepository
        self.userRepository = userRepository
    }

    let imageRepository: any ImageRepository
    let userRepository: any UserRepository
}

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: DetailViewModel

    var body: some View {
        VStack {
            Text("Detail")
            Button("dismiss") {
                dismiss()
            }
        }.padding()
    }
}
