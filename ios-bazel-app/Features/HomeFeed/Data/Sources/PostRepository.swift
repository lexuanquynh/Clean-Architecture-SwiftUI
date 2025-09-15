import Foundation
import Combine
import CoreDomain
import CoreData
import HomeFeedDomain

// MARK: - Post Repository Implementation
public class PostRepository: PostRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let sessionManager: SessionManager
    private var mockPosts: [Post] = []
    
    public init(
        networkManager: NetworkManagerProtocol = NetworkManager.shared,
        sessionManager: SessionManager = SessionManager.shared
    ) {
        self.networkManager = networkManager
        self.sessionManager = sessionManager
        generateMockPosts()
    }
    
    private func generateMockPosts() {
        let authors = [
            User(id: "1", email: "john@example.com", name: "John Doe", avatarURL: "https://i.pravatar.cc/150?img=1"),
            User(id: "2", email: "jane@example.com", name: "Jane Smith", avatarURL: "https://i.pravatar.cc/150?img=2"),
            User(id: "3", email: "bob@example.com", name: "Bob Johnson", avatarURL: "https://i.pravatar.cc/150?img=3"),
            User(id: "4", email: "alice@example.com", name: "Alice Williams", avatarURL: "https://i.pravatar.cc/150?img=4"),
            User(id: "5", email: "charlie@example.com", name: "Charlie Brown", avatarURL: "https://i.pravatar.cc/150?img=5")
        ]
        
        let titles = [
            "Getting Started with SwiftUI",
            "Clean Architecture in iOS",
            "Building with Bazel",
            "Combine Framework Deep Dive",
            "iOS App Performance Tips",
            "Modern Swift Concurrency",
            "UI Testing Best Practices",
            "Dependency Injection Patterns",
            "SwiftUI Animation Techniques",
            "iOS Security Guidelines"
        ]
        
        let contents = [
            "SwiftUI is Apple's modern declarative framework for building user interfaces across all Apple platforms. It provides a simple and intuitive way to build complex UIs with less code.",
            "Clean Architecture helps separate concerns and makes your iOS app more maintainable, testable, and scalable. Learn the key principles and how to apply them.",
            "Bazel is a powerful build tool that enables fast, reliable builds for large-scale projects. Discover how to integrate it into your iOS development workflow.",
            "The Combine framework provides a declarative Swift API for processing values over time. Master reactive programming in iOS with practical examples.",
            "Optimize your iOS app's performance with these proven techniques. From memory management to rendering optimization, cover all aspects of app performance.",
            "Swift's new async/await syntax and structured concurrency make asynchronous code easier to write and understand. Explore the latest concurrency features.",
            "Ensure your app works correctly with comprehensive UI testing. Learn strategies for writing maintainable and reliable UI tests.",
            "Dependency injection is a fundamental pattern for writing testable and maintainable code. Explore different DI approaches in Swift.",
            "Create stunning animations in SwiftUI with ease. From basic transitions to complex custom animations, master the animation APIs.",
            "Protect your users' data and maintain app security. Learn about common vulnerabilities and best practices for iOS security."
        ]
        
        // Generate 50 mock posts
        for i in 1...50 {
            let author = authors.randomElement()!
            let title = titles.randomElement()!
            let content = contents.randomElement()!
            let hasImage = Bool.random()
            
            let post = Post(
                id: UUID().uuidString,
                title: "\(title) - Part \(i)",
                content: "\(content)\n\nThis is post number \(i) in our feed. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                author: author,
                imageURL: hasImage ? "https://picsum.photos/400/300?random=\(i)" : nil,
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                likesCount: Int.random(in: 0...1000),
                isLiked: Bool.random()
            )
            mockPosts.append(post)
        }
    }
    
    public func fetchPosts(page: Int, limit: Int) async throws -> [Post] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Calculate pagination
        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, mockPosts.count)
        
        guard startIndex < mockPosts.count else {
            return []
        }
        
        return Array(mockPosts[startIndex..<endIndex])
    }
    
    public func fetchPost(id: String) async throws -> Post {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let post = mockPosts.first(where: { $0.id == id }) else {
            throw DomainError.notFound
        }
        
        return post
    }
    
    public func likePost(id: String) async throws -> Post {
        // Check if user is logged in
        guard sessionManager.currentUser != nil else {
            throw DomainError.unauthorized
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        guard let index = mockPosts.firstIndex(where: { $0.id == id }) else {
            throw DomainError.notFound
        }
        
        var post = mockPosts[index]
        post = Post(
            id: post.id,
            title: post.title,
            content: post.content,
            author: post.author,
            imageURL: post.imageURL,
            createdAt: post.createdAt,
            likesCount: post.isLiked ? post.likesCount : post.likesCount + 1,
            isLiked: true
        )
        mockPosts[index] = post
        
        return post
    }
    
    public func unlikePost(id: String) async throws -> Post {
        // Check if user is logged in
        guard sessionManager.currentUser != nil else {
            throw DomainError.unauthorized
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        guard let index = mockPosts.firstIndex(where: { $0.id == id }) else {
            throw DomainError.notFound
        }
        
        var post = mockPosts[index]
        post = Post(
            id: post.id,
            title: post.title,
            content: post.content,
            author: post.author,
            imageURL: post.imageURL,
            createdAt: post.createdAt,
            likesCount: post.isLiked ? max(0, post.likesCount - 1) : post.likesCount,
            isLiked: false
        )
        mockPosts[index] = post
        
        return post
    }
    
    public func createPost(title: String, content: String, imageData: Data?) async throws -> Post {
        // Check if user is logged in
        guard let currentUser = sessionManager.currentUser else {
            throw DomainError.unauthorized
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let newPost = Post(
            id: UUID().uuidString,
            title: title,
            content: content,
            author: currentUser,
            imageURL: imageData != nil ? "https://picsum.photos/400/300?random=\(UUID().uuidString)" : nil,
            createdAt: Date(),
            likesCount: 0,
            isLiked: false
        )
        
        mockPosts.insert(newPost, at: 0)
        
        return newPost
    }
    
    public func deletePost(id: String) async throws {
        // Check if user is logged in
        guard let currentUser = sessionManager.currentUser else {
            throw DomainError.unauthorized
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let index = mockPosts.firstIndex(where: { $0.id == id }) else {
            throw DomainError.notFound
        }
        
        // Check if user owns the post
        guard mockPosts[index].author.id == currentUser.id else {
            throw DomainError.unauthorized
        }
        
        mockPosts.remove(at: index)
    }
    
    public func searchPosts(query: String) async throws -> [Post] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        
        let lowercasedQuery = query.lowercased()
        
        return mockPosts.filter { post in
            post.title.lowercased().contains(lowercasedQuery) ||
            post.content.lowercased().contains(lowercasedQuery) ||
            post.author.name.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - DTO Models
struct PostDTO: Codable {
    let id: String
    let title: String
    let content: String
    let authorId: String
    let authorName: String
    let authorEmail: String
    let authorAvatarURL: String?
    let imageURL: String?
    let createdAt: String
    let likesCount: Int
    let isLiked: Bool
    
    func toDomain() -> Post {
        let author = User(
            id: authorId,
            email: authorEmail,
            name: authorName,
            avatarURL: authorAvatarURL
        )
        
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: createdAt) ?? Date()
        
        return Post(
            id: id,
            title: title,
            content: content,
            author: author,
            imageURL: imageURL,
            createdAt: date,
            likesCount: likesCount,
            isLiked: isLiked
        )
    }
}

struct PostsResponse: Codable {
    let posts: [PostDTO]
    let totalCount: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
}
