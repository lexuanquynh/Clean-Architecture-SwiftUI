import Foundation
import Combine
import CoreDomain

// MARK: - Network Manager
public protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload<T: Decodable>(_ endpoint: Endpoint, data: Data) async throws -> T
}

public struct Endpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public var body: Data?
    public let queryItems: [URLQueryItem]?
    
    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public class NetworkManager: NetworkManagerProtocol {
    private let baseURL: String
    private let session: URLSession
    
    public static let shared = NetworkManager()
    
    public init(
        baseURL: String = "https://api.example.com",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw DomainError.networkError("Invalid URL")
        }
        
        urlComponents.queryItems = endpoint.queryItems
        
        guard let url = urlComponents.url else {
            throw DomainError.networkError("Invalid URL components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DomainError.networkError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            case 401:
                throw DomainError.unauthorized
            case 404:
                throw DomainError.notFound
            default:
                throw DomainError.networkError("Status code: \(httpResponse.statusCode)")
            }
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.unknown(error)
        }
    }
    
    public func upload<T: Decodable>(_ endpoint: Endpoint, data: Data) async throws -> T {
        var modifiedEndpoint = endpoint
        modifiedEndpoint.body = data
        return try await request(modifiedEndpoint)
    }
}

// MARK: - Base Repository Implementation
open class BaseRepository<T: Entity> {
    public let networkManager: NetworkManagerProtocol
    
    public init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
}

// MARK: - Cache Manager
public protocol CacheManagerProtocol {
    func save<T: Codable>(_ object: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func clearAll()
}

public class CacheManager: CacheManagerProtocol {
    public static let shared = CacheManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    public func save<T: Codable>(_ object: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    public func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    public func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - Session Manager
public class SessionManager: ObservableObject {
    public static let shared = SessionManager()
    
    @Published public var currentUser: User?
    @Published public var isLoggedIn: Bool = false
    
    private let cacheManager: CacheManagerProtocol
    private let userKey = "current_user"
    
    public init(cacheManager: CacheManagerProtocol = CacheManager.shared) {
        self.cacheManager = cacheManager
        loadUser()
    }
    
    public func saveUser(_ user: User) {
        currentUser = user
        isLoggedIn = true
        cacheManager.save(user, forKey: userKey)
    }
    
    public func clearSession() {
        currentUser = nil
        isLoggedIn = false
        cacheManager.remove(forKey: userKey)
    }
    
    private func loadUser() {
        if let user = cacheManager.load(User.self, forKey: userKey) {
            currentUser = user
            isLoggedIn = true
        }
    }
}
