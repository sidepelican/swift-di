struct Request {
    var eventLoop: any EventLoop = RequestEventLoop()
    var header: [String: String] = [:]
}

struct User {}

struct UserManager {
    var request: Request
    var repository: any Repository

    func authenticate() async throws -> User {
        if let _ = request.header.first(where: { $0.key == "Authenticate" }) {
            guard let user = try await repository.fetchUser(id: "xxxxx") else {
                throw Abort()
            }
            return user
        }
        throw Abort()
    }
}

struct UserController {
    var user: User

    func getUser() -> User {
        user
    }
}

struct ListUserCommand {
    var repository: any Repository
    func run() async throws {
        print(try await repository.listUser())
    }
}

struct Abort: Error {}

protocol Repository: Sendable {
    func fetchUser(id: String) async throws -> User?
    func listUser() async throws -> [User]
}

struct DatabaseRepository: Repository {
    var eventLoop: any EventLoop
    func fetchUser(id: String) async throws -> User? {
        print("\(#function) on eventLoop[\(eventLoop.name)]")
        return User()
    }
    func listUser() async throws -> [User] {
        print("\(#function) on eventLoop[\(eventLoop.name)]")
        return [User()]
    }
}

protocol EventLoop: Sendable {
    var name: String { get }
}

extension EventLoop where Self == SingletonEventLoop {
    static var singleton: Self {
        SingletonEventLoop.shared
    }
}

final class SingletonEventLoop: EventLoop {
    var name: String { "singleton" }
    static let shared = SingletonEventLoop()
}

private nonisolated(unsafe) var counter = 0
final class RequestEventLoop: EventLoop {
    var name: String { "request-\(id)" }
    let id: Int
    init() {
        self.id = counter
        counter += 1
    }
}
