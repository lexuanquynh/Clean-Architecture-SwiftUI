import SwiftUI
import CorePresentation
import CoreDomain

// MARK: - Login View
public struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var animateGradient = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Login Form
                        VStack(spacing: 16) {
                            // Email Field
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }
                            .customTextFieldStyle()
                            
                            // Password Field
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                if viewModel.isPasswordVisible {
                                    TextField("Password", text: $viewModel.password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Password", text: $viewModel.password)
                                        .textContentType(.password)
                                }
                                Button(action: { viewModel.isPasswordVisible.toggle() }) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .customTextFieldStyle()
                            
                            // Remember Me & Forgot Password
                            HStack {
                                Toggle("Remember me", isOn: $viewModel.rememberMe)
                                    .toggleStyle(CheckboxToggleStyle())
                                
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    viewModel.forgotPassword()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 4)
                            
                            // Login Button
                            Button(action: {
                                Task {
                                    await viewModel.login()
                                }
                            }) {
                                Text("Login")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!viewModel.isFormValid || viewModel.isLoading)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.vertical, 8)
                            
                            // Social Login Buttons
                            VStack(spacing: 12) {
                                SocialLoginButton(
                                    title: "Continue with Apple",
                                    icon: "apple.logo",
                                    backgroundColor: .black
                                )
                                
                                SocialLoginButton(
                                    title: "Continue with Google",
                                    icon: "globe",
                                    backgroundColor: .red
                                )
                            }
                            
                            // Register Link
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                NavigationLink(destination: RegisterView()) {
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.footnote)
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .navigationDestination(isPresented: $viewModel.loginSuccessful) {
                Text("Home Screen") // This will be replaced with HomeFeed
            }
        }
    }
}

// MARK: - Register View
public struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        // Name Field
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("Full Name", text: $viewModel.name)
                                .textContentType(.name)
                        }
                        .customTextFieldStyle()
                        
                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                            TextField("Email", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }
                        .customTextFieldStyle()
                        
                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $viewModel.password)
                                .textContentType(.newPassword)
                        }
                        .customTextFieldStyle()
                        
                        // Confirm Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                            if !viewModel.confirmPassword.isEmpty {
                                Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.passwordsMatch ? .green : .red)
                            }
                        }
                        .customTextFieldStyle()
                        
                        // Terms and Conditions
                        Toggle(isOn: $viewModel.agreedToTerms) {
                            HStack(spacing: 4) {
                                Text("I agree to the")
                                    .font(.caption)
                                Text("Terms and Conditions")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        // Register Button
                        Button(action: {
                            Task {
                                await viewModel.register()
                            }
                        }) {
                            Text("Create Account")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        
                        // Login Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            Button("Sign In") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        }
                        .font(.footnote)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .navigationDestination(isPresented: $viewModel.registrationSuccessful) {
            Text("Welcome Screen") // This will be replaced with onboarding
        }
    }
}

// MARK: - Helper Views
struct SocialLoginButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView()
        }
    }
}
