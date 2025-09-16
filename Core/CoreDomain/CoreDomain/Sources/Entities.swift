import Foundation

// MARK: - Base Entities
public protocol Entity {
    associatedtype ID: Hashable
    var id: ID { get }
}

// MARK: - User Entity
public struct User: Entity, Codable {
    public let id: String
    public let email: String
    public let name: String
    public let avatarURL: String?
    public let accessToken: String?
    
    public init(
        id: String,
        email: String,
        name: String,
        avatarURL: String? = nil,
        accessToken: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
        self.accessToken = accessToken
    }
}

// MARK: - Post Entity
public struct Post: Entity {
    public let id: String
    public let title: String
    public let content: String
    public let author: User
    public let imageURL: String?
    public let createdAt: Date
    public let likesCount: Int
    public let isLiked: Bool
    
    public init(
        id: String,
        title: String,
        content: String,
        author: User,
        imageURL: String? = nil,
        createdAt: Date,
        likesCount: Int = 0,
        isLiked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.author = author
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.isLiked = isLiked
    }
}

// MARK: - Base Repository Protocol
public protocol Repository {
    associatedtype T: Entity
    func fetch(id: T.ID) async throws -> T
    func fetchAll() async throws -> [T]
    func save(_ entity: T) async throws -> T
    func delete(id: T.ID) async throws
}

// MARK: - Base UseCase Protocol
public protocol UseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async throws -> Output
}

// MARK: - Result Type
public enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}

// MARK: - Common Errors
public enum DomainError: Error, LocalizedError {
    case notFound
    case unauthorized
    case networkError(String)
    case validationError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
