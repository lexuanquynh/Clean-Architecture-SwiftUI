import Foundation
import Combine
import CoreDomain

// MARK: - Post Repository Protocol
public protocol PostRepositoryProtocol {
    func fetchPosts(page: Int, limit: Int) async throws -> [Post]
    func fetchPost(id: String) async throws -> Post
    func likePost(id: String) async throws -> Post
    func unlikePost(id: String) async throws -> Post
    func createPost(title: String, content: String, imageData: Data?) async throws -> Post
    func deletePost(id: String) async throws
    func searchPosts(query: String) async throws -> [Post]
}

// MARK: - Fetch Posts Use Case
public protocol FetchPostsUseCaseProtocol: UseCase where Input == FetchPostsInput, Output == [Post] {}

public struct FetchPostsInput {
    public let page: Int
    public let limit: Int
    
    public init(page: Int = 1, limit: Int = 20) {
        self.page = page
        self.limit = limit
    }
}

public class FetchPostsUseCase: FetchPostsUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: FetchPostsInput) async throws -> [Post] {
        guard input.page > 0 else {
            throw DomainError.validationError("Page must be greater than 0")
        }
        
        guard input.limit > 0 && input.limit <= 100 else {
            throw DomainError.validationError("Limit must be between 1 and 100")
        }
        
        return try await repository.fetchPosts(page: input.page, limit: input.limit)
    }
}

// MARK: - Like Post Use Case
public protocol LikePostUseCaseProtocol: UseCase where Input == String, Output == Post {}

public class LikePostUseCase: LikePostUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ postId: String) async throws -> Post {
        guard !postId.isEmpty else {
            throw DomainError.validationError("Post ID is required")
        }
        
        return try await repository.likePost(id: postId)
    }
}

// MARK: - Unlike Post Use Case
public protocol UnlikePostUseCaseProtocol: UseCase where Input == String, Output == Post {}

public class UnlikePostUseCase: UnlikePostUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ postId: String) async throws -> Post {
        guard !postId.isEmpty else {
            throw DomainError.validationError("Post ID is required")
        }
        
        return try await repository.unlikePost(id: postId)
    }
}

// MARK: - Create Post Use Case
public protocol CreatePostUseCaseProtocol: UseCase where Input == CreatePostInput, Output == Post {}

public struct CreatePostInput {
    public let title: String
    public let content: String
    public let imageData: Data?
    
    public init(title: String, content: String, imageData: Data? = nil) {
        self.title = title
        self.content = content
        self.imageData = imageData
    }
}

public class CreatePostUseCase: CreatePostUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: CreatePostInput) async throws -> Post {
        // Validate input
        guard !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.validationError("Title is required")
        }
        
        guard input.title.count <= 200 else {
            throw DomainError.validationError("Title must be less than 200 characters")
        }
        
        guard !input.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.validationError("Content is required")
        }
        
        guard input.content.count <= 5000 else {
            throw DomainError.validationError("Content must be less than 5000 characters")
        }
        
        if let imageData = input.imageData {
            guard imageData.count <= 10 * 1024 * 1024 else { // 10MB limit
                throw DomainError.validationError("Image must be less than 10MB")
            }
        }
        
        return try await repository.createPost(
            title: input.title,
            content: input.content,
            imageData: input.imageData
        )
    }
}

// MARK: - Delete Post Use Case
public protocol DeletePostUseCaseProtocol: UseCase where Input == String, Output == Void {}

public class DeletePostUseCase: DeletePostUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ postId: String) async throws {
        guard !postId.isEmpty else {
            throw DomainError.validationError("Post ID is required")
        }
        
        try await repository.deletePost(id: postId)
    }
}

// MARK: - Search Posts Use Case
public protocol SearchPostsUseCaseProtocol: UseCase where Input == String, Output == [Post] {}

public class SearchPostsUseCase: SearchPostsUseCaseProtocol {
    private let repository: PostRepositoryProtocol
    
    public init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ query: String) async throws -> [Post] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            return []
        }
        
        guard trimmedQuery.count >= 2 else {
            throw DomainError.validationError("Search query must be at least 2 characters")
        }
        
        return try await repository.searchPosts(query: trimmedQuery)
    }
}
