import SwiftUI
import Combine
import CoreDomain

// MARK: - Base ViewModel
open class BaseViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var showError = false
    
    public var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    public func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            if let domainError = error as? DomainError {
                self?.errorMessage = domainError.errorDescription
            } else {
                self?.errorMessage = error.localizedDescription
            }
            self?.showError = true
        }
    }
    
    public func startLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
    }
    
    public func stopLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }
}

// MARK: - Loading View
public struct LoadingView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Error View
public struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    public init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Empty State View
public struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(
        title: String,
        message: String,
        systemImage: String = "doc.text.magnifyingglass",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Custom Button Styles
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isEnabled ? Color.blue : Color.gray
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Custom TextField Style
public struct CustomTextFieldStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

extension View {
    public func customTextFieldStyle() -> some View {
        modifier(CustomTextFieldStyle())
    }
}

// MARK: - Navigation Coordinator
public protocol Coordinator: ObservableObject {
    associatedtype Route
    var navigationPath: [Route] { get set }
    func push(_ route: Route)
    func pop()
    func popToRoot()
}

open class BaseCoordinator<Route>: ObservableObject, Coordinator {
    @Published public var navigationPath: [Route] = []
    
    public init() {}
    
    public func push(_ route: Route) {
        navigationPath.append(route)
    }
    
    public func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    public func popToRoot() {
        navigationPath.removeAll()
    }
}
