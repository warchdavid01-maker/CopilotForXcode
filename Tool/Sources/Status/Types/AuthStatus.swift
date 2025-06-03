public struct AuthStatus: Equatable {
    public enum Status { case unknown, loggedIn, notLoggedIn, notAuthorized }
    public let status: Status
    public let username: String?
    public let message: String?
}
