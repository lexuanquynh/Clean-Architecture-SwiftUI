import Foundation
import Combine
import CoreDomain

// MARK: - Authentication Repository Protocol
public protocol AuthenticationRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func register(email: String, password: String, name: String) async throws -> User
    func refreshToken(_ token: String) async throws -> String
    func validateToken(_ token: String) async throws -> Bool
}

// MARK: - Login Use Case
public protocol LoginUseCaseProtocol: UseCase where Input == LoginInput, Output == User {}

public struct LoginInput {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthenticationRepositoryProtocol
    
    public init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: LoginInput) async throws -> User {
        // Validate input
        guard !input.email.isEmpty else {
            throw DomainError.validationError("Email is required")
        }
        
        guard isValidEmail(input.email) else {
            throw DomainError.validationError("Invalid email format")
        }
        
        guard !input.password.isEmpty else {
            throw DomainError.validationError("Password is required")
        }
        
        guard input.password.count >= 6 else {
            throw DomainError.validationError("Password must be at least 6 characters")
        }
        
        // Perform login
        return try await repository.login(email: input.email, password: input.password)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Logout Use Case
public protocol LogoutUseCaseProtocol: UseCase where Input == Void, Output == Void {}

public class LogoutUseCase: LogoutUseCaseProtocol {
    private let repository: AuthenticationRepositoryProtocol
    
    public init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: Void) async throws -> Void {
        try await repository.logout()
    }
}

// MARK: - Register Use Case
public protocol RegisterUseCaseProtocol: UseCase where Input == RegisterInput, Output == User {}

public struct RegisterInput {
    public let email: String
    public let password: String
    public let confirmPassword: String
    public let name: String
    
    public init(email: String, password: String, confirmPassword: String, name: String) {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.name = name
    }
}

public class RegisterUseCase: RegisterUseCaseProtocol {
    private let repository: AuthenticationRepositoryProtocol
    
    public init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: RegisterInput) async throws -> User {
        // Validate input
        guard !input.name.isEmpty else {
            throw DomainError.validationError("Name is required")
        }
        
        guard !input.email.isEmpty else {
            throw DomainError.validationError("Email is required")
        }
        
        guard isValidEmail(input.email) else {
            throw DomainError.validationError("Invalid email format")
        }
        
        guard !input.password.isEmpty else {
            throw DomainError.validationError("Password is required")
        }
        
        guard input.password.count >= 6 else {
            throw DomainError.validationError("Password must be at least 6 characters")
        }
        
        guard input.password == input.confirmPassword else {
            throw DomainError.validationError("Passwords do not match")
        }
        
        // Perform registration
        return try await repository.register(
            email: input.email,
            password: input.password,
            name: input.name
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Token Validation Use Case
public protocol ValidateTokenUseCaseProtocol: UseCase where Input == String, Output == Bool {}

public class ValidateTokenUseCase: ValidateTokenUseCaseProtocol {
    private let repository: AuthenticationRepositoryProtocol
    
    public init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ input: String) async throws -> Bool {
        return try await repository.validateToken(input)
    }
}
