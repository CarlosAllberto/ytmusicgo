// Substitui o Auth do app: sem cookies, tudo anônimo.
@MainActor final class Auth {
    static let shared = Auth()
    func headers() async -> [String: String]? { nil }
}
