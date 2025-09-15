import SwiftUI
import Combine
import CoreDomain
import CorePresentation
import AuthenticationDomain
import AuthenticationData

// MARK: - Login ViewModel
public class LoginViewModel: BaseViewModel {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var isPasswordVisible = false
    @Published public var rememberMe = false
    @Published public var loginSuccessful = false
    @Published public var navigateToRegister = false
    
    private let loginUseCase: LoginUseCaseProtocol
    private let logoutUseCase: LogoutUseCaseProtocol
    
    public var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    public init(
        loginUseCase: LoginUseCaseProtocol? = nil,
        logoutUseCase: LogoutUseCaseProtocol? = nil
    ) {
        let repository = AuthenticationRepository()
        self.loginUseCase = loginUseCase ?? LoginUseCase(repository: repository)
        self.logoutUseCase = logoutUseCase ?? LogoutUseCase(repository: repository)
        super.init()
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-dismiss error after 3 seconds
        $showError
            .filter { $0 }
            .delay(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.showError = false
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    public func login() async {
        startLoading()
        
        do {
            let input = LoginInput(email: email, password: password)
            let user = try await loginUseCase.execute(input)
            
            stopLoading()
            loginSuccessful = true
            
            // Clear form
            email = ""
            password = ""
            
            print("Login successful for user: \(user.name)")
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    public func logout() async {
        startLoading()
        
        do {
            try await logoutUseCase.execute(())
            stopLoading()
            loginSuccessful = false
        } catch {
            handleError(error)
        }
    }
    
    public func forgotPassword() {
        // Navigate to forgot password screen
        print("Navigate to forgot password")
    }
    
    public func navigateToRegistration() {
        navigateToRegister = true
    }
}

// MARK: - Register ViewModel
public class RegisterViewModel: BaseViewModel {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public var name = ""
    @Published public var agreedToTerms = false
    @Published public var registrationSuccessful = false
    
    private let registerUseCase: RegisterUseCaseProtocol
    
    public var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !name.isEmpty &&
        agreedToTerms
    }
    
    public var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    public init(registerUseCase: RegisterUseCaseProtocol? = nil) {
        let repository = AuthenticationRepository()
        self.registerUseCase = registerUseCase ?? RegisterUseCase(repository: repository)
        super.init()
    }
    
    @MainActor
    public func register() async {
        startLoading()
        
        do {
            let input = RegisterInput(
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                name: name
            )
            
            let user = try await registerUseCase.execute(input)
            
            stopLoading()
            registrationSuccessful = true
            
            print("Registration successful for user: \(user.name)")
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Authentication Coordinator
public class AuthenticationCoordinator: BaseCoordinator<AuthenticationRoute> {
    public enum AuthenticationRoute {
        case login
        case register
        case forgotPassword
        case verification(email: String)
    }
    
    @Published public var isAuthenticated = false
    
    public override init() {
        super.init()
    }
    
    public func navigateToLogin() {
        popToRoot()
        push(.login)
    }
    
    public func navigateToRegister() {
        push(.register)
    }
    
    public func navigateToForgotPassword() {
        push(.forgotPassword)
    }
    
    public func navigateToVerification(email: String) {
        push(.verification(email: email))
    }
    
    public func completeAuthentication() {
        isAuthenticated = true
        popToRoot()
    }
}
