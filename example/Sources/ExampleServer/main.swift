let rootComponent = RootComponent()

for i in 0..<3 {
    do {
        var request = Request()
        if i != 1 {
            request.header["Authenticate"] = "Beaerer xxxxxx"
        }

        let requestComponent = rootComponent
            .requestComponent(request: request)

        let user = try await requestComponent.userManager().authenticate()

        let userController = AuthenticatedComponent(
            parent: requestComponent,
            user: user
        ).userController()

        print(userController.getUser())
    } catch {
        print("\(error)")
    }
}

do {
    let command = rootComponent.commandComponent().listUserCommand()
    try await command.run()
} catch {
    print("\(error)")
}
