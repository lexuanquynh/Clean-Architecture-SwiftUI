import Foundation
import Combine
import CoreDomain
import CoreData
import AuthenticationDomain

// MARK: - Authentication Repository Implementation
public class AuthenticationRepository: AuthenticationRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let sessionManager: SessionManager
    
    public init(
        networkManager: NetworkManagerProtocol = NetworkManager.shared,
        sessionManager: SessionManager = SessionManager.shared
    ) {
        self.networkManager = networkManager
        self.sessionManager = sessionManager
    }
    
    public func login(email: String, password: String) async throws -> User {
        // In a real app, this would make an API call
        // For demo purposes, we'll simulate a network call
        
        let endpoint = Endpoint(
            path: "/auth/login",
            method: .post,
            body: try? JSONEncoder().encode([
                "email": email,
                "password": password
            ])
        )
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock response for demo
        if email == "test@example.com" && password == "password" {
            let user = User(
                id: UUID().uuidString,
                email: email,
                name: "Test User",
                avatarURL: "https://example.com/avatar.jpg",
                accessToken: "mock_token_\(UUID().uuidString)"
            )
            
            // Save user to session
            sessionManager.saveUser(user)
            
            return user
        } else {
            throw DomainError.unauthorized
        }
    }
    
    public func logout() async throws {
        // Clear session
        sessionManager.clearSession()
        
        // In a real app, this might also call an API endpoint to invalidate the token
        let endpoint = Endpoint(
            path: "/auth/logout",
            method: .post,
            headers: ["Authorization": "Bearer \(sessionManager.currentUser?.accessToken ?? "")"]
        )
        
        // Simulate network call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    public func register(email: String, password: String, name: String) async throws -> User {
        let endpoint = Endpoint(
            path: "/auth/register",
            method: .post,
            body: try? JSONEncoder().encode([
                "email": email,
                "password": password,
                "name": name
            ])
        )
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock response for demo
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            avatarURL: nil,
            accessToken: "mock_token_\(UUID().uuidString)"
        )
        
        // Save user to session
        sessionManager.saveUser(user)
        
        return user
    }
    
    public func refreshToken(_ token: String) async throws -> String {
        let endpoint = Endpoint(
            path: "/auth/refresh",
            method: .post,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock response
        return "refreshed_token_\(UUID().uuidString)"
    }
    
    public func validateToken(_ token: String) async throws -> Bool {
        let endpoint = Endpoint(
            path: "/auth/validate",
            method: .get,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Mock validation
        return !token.isEmpty && token.starts(with: "mock_token_")
    }
}

// MARK: - DTO Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let user: UserDTO
    let accessToken: String
    let refreshToken: String
}

struct UserDTO: Codable {
    let id: String
    let email: String
    let name: String
    let avatarURL: String?
    
    func toDomain(accessToken: String? = nil) -> User {
        return User(
            id: id,
            email: email,
            name: name,
            avatarURL: avatarURL,
            accessToken: accessToken
        )
    }
}
