struct Request {
    var eventLoop: any EventLoop
    var header: [String: String] = [:]
}

struct User {}

struct UserManager {
    var request: Request

    func authenticate() async throws -> User? {
        if let _ = request.header.first(where: { $0.key == "Authenticate" }) {
            return User()
        }
        return nil
    }
}

struct UserController {
    var user: User
    var repository: any Repository
}

struct Abort: Error {}

protocol Repository: Sendable {}

struct DatabaseRepository: Repository {
    var eventLoop: any EventLoop
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
