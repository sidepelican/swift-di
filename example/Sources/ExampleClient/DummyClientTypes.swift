import Foundation

protocol UserRepository: Sendable {
}

protocol ImageRepository: Sendable {
}

struct APIClient {
    var session: URLSession
}

struct APIUserRepository: UserRepository {
    var apiClient: APIClient
}

struct NetworkImageRepository: ImageRepository {
    var urlSession: URLSession
}

struct LocalImageRepository: ImageRepository {
}
