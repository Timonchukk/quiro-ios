import SwiftUI

/// Auth screen redesigned to match Android's AuthScreen.kt.
/// Card-based layout with outlined fields, indigo accent, text logo with pulse.
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ZStack {
            // Background — solid dark, matches Android DarkBg #050505
            Color(red: 0.02, green: 0.02, blue: 0.02)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    // Logo (text-based, matches Android QurioLogo)
                    QurioLogo()
                    
                    Spacer().frame(height: 32)
                    
                    // Card container
                    VStack(spacing: 0) {
                        // Error / Success messages
                        if let error = viewModel.errorMessage {
                            errorBanner(message: error)
                                .padding(.bottom, 16)
                        }
                        
                        if let success = viewModel.successMessage {
                            successBanner(message: success)
                                .padding(.bottom, 16)
                        }
                        
                        // Content based on state
                        switch viewModel.screenState {
                        case .login:
                            loginContent
                        case .register:
                            registerContent
                        case .verify:
                            verifyContent
                        case .forgotPassword:
                            forgotPasswordContent
                        case .resetPassword:
                            resetPasswordContent
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.047, green: 0.047, blue: 0.047)) // #0C0C0C
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 0.133, green: 0.133, blue: 0.133), lineWidth: 1) // #222222
                    )
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }
    
    // MARK: - Login
    
    private var loginContent: some View {
        VStack(spacing: 0) {
            Text("Увійти")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.authTextPrimary)
            
            Spacer().frame(height: 4)
            
            HStack(spacing: 4) {
                Text("Ще немає акаунту?")
                    .foregroundColor(.authTextMuted)
                Button("Створити") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .register
                }
                .foregroundColor(.authAccent)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            
            Spacer().frame(height: 20)
            
            // Google button first (matches Android layout order)
            googleSignInButton
            
            // Terms notice
            googleTermsNotice
            
            Spacer().frame(height: 16)
            orDivider
            Spacer().frame(height: 16)
            
            // Email
            AuthOutlinedField(
                value: $viewModel.loginEmail,
                label: "Електронна пошта",
                placeholder: "alex@email.com",
                keyboardType: .emailAddress
            )
            
            Spacer().frame(height: 12)
            
            // Password
            AuthOutlinedField(
                value: $viewModel.loginPassword,
                label: "Пароль",
                placeholder: "Ваш пароль",
                isSecure: !viewModel.showLoginPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showLoginPassword,
                onTogglePassword: { viewModel.showLoginPassword.toggle() }
            )
            
            Spacer().frame(height: 20)
            
            // Login button
            PrimaryActionButton("Увійти →", isLoading: viewModel.isLoading) {
                Task { await viewModel.login() }
            }
            
            Spacer().frame(height: 12)
            
            // Forgot password
            Button("Забули пароль?") {
                viewModel.errorMessage = nil
                viewModel.screenState = .forgotPassword
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.authAccent)
        }
    }
    
    // MARK: - Register
    
    private var registerContent: some View {
        VStack(spacing: 0) {
            Text("Створити акаунт")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.authTextPrimary)
            
            Spacer().frame(height: 4)
            
            HStack(spacing: 4) {
                Text("Вже є акаунт?")
                    .foregroundColor(.authTextMuted)
                Button("Увійти") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .login
                }
                .foregroundColor(.authAccent)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            
            Spacer().frame(height: 20)
            
            googleSignInButton
            googleTermsNotice
            
            Spacer().frame(height: 16)
            orDivider
            Spacer().frame(height: 16)
            
            AuthOutlinedField(
                value: $viewModel.registerName,
                label: "Повне ім'я",
                placeholder: "Олексій Коваль"
            )
            
            Spacer().frame(height: 12)
            
            AuthOutlinedField(
                value: $viewModel.registerEmail,
                label: "Електронна пошта",
                placeholder: "alex@email.com",
                keyboardType: .emailAddress
            )
            
            Spacer().frame(height: 12)
            
            AuthOutlinedField(
                value: $viewModel.registerPassword,
                label: "Пароль",
                placeholder: "Мінімум 8 символів",
                isSecure: !viewModel.showRegisterPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showRegisterPassword,
                onTogglePassword: { viewModel.showRegisterPassword.toggle() }
            )
            
            Spacer().frame(height: 12)
            
            AuthOutlinedField(
                value: $viewModel.registerPassword2,
                label: "Підтвердіть пароль",
                placeholder: "Повторіть пароль",
                isSecure: !viewModel.showRegisterPassword
            )
            
            Spacer().frame(height: 16)
            
            PrimaryActionButton("Створити акаунт →", isLoading: viewModel.isLoading) {
                Task { await viewModel.register() }
            }
        }
    }
    
    // MARK: - Verify
    
    private var verifyContent: some View {
        VStack(spacing: 0) {
            Text("📬")
                .font(.system(size: 40))
            
            Spacer().frame(height: 12)
            
            Text("Підтвердіть email")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.authTextPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Ми надіслали 6-значний код на\n\(viewModel.verifyEmail)")
                .font(.system(size: 14))
                .foregroundColor(.authTextMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            AuthOutlinedField(
                value: $viewModel.verifyCode,
                label: "Код підтвердження",
                placeholder: "000000",
                keyboardType: .numberPad
            )
            
            Spacer().frame(height: 20)
            
            PrimaryActionButton("Підтвердити →", isLoading: viewModel.isLoading) {
                Task { await viewModel.verify() }
            }
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(.authTextMuted)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundColor(.authAccent)
                .fontWeight(.semibold)
            }
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Forgot Password
    
    private var forgotPasswordContent: some View {
        VStack(spacing: 0) {
            Text("🔑")
                .font(.system(size: 40))
            
            Spacer().frame(height: 12)
            
            Text("Забули пароль?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.authTextPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Введіть email, і ми надішлемо\nкод для скидання паролю.")
                .font(.system(size: 14))
                .foregroundColor(.authTextMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            AuthOutlinedField(
                value: $viewModel.forgotEmail,
                label: "Електронна пошта",
                placeholder: "alex@email.com",
                keyboardType: .emailAddress
            )
            
            Spacer().frame(height: 20)
            
            PrimaryActionButton("Надіслати код →", isLoading: viewModel.isLoading) {
                Task { await viewModel.forgotPassword() }
            }
            
            Spacer().frame(height: 16)
            
            Button("← Повернутись до входу") {
                viewModel.errorMessage = nil
                viewModel.screenState = .login
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.authAccent)
        }
    }
    
    // MARK: - Reset Password
    
    private var resetPasswordContent: some View {
        VStack(spacing: 0) {
            Text("🔒")
                .font(.system(size: 40))
            
            Spacer().frame(height: 12)
            
            Text("Новий пароль")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.authTextPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Введіть код з листа та новий пароль")
                .font(.system(size: 14))
                .foregroundColor(.authTextMuted)
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 24)
            
            AuthOutlinedField(
                value: $viewModel.resetCode,
                label: "Код з листа",
                placeholder: "123456",
                keyboardType: .numberPad
            )
            
            Spacer().frame(height: 12)
            
            AuthOutlinedField(
                value: $viewModel.resetPassword,
                label: "Новий пароль",
                placeholder: "Мінімум 8 символів",
                isSecure: !viewModel.showResetPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showResetPassword,
                onTogglePassword: { viewModel.showResetPassword.toggle() }
            )
            
            Spacer().frame(height: 12)
            
            AuthOutlinedField(
                value: $viewModel.resetPassword2,
                label: "Підтвердіть пароль",
                placeholder: "Повторіть пароль",
                isSecure: !viewModel.showResetPassword
            )
            
            Spacer().frame(height: 20)
            
            PrimaryActionButton("Скинути пароль →", isLoading: viewModel.isLoading) {
                Task { await viewModel.doResetPassword() }
            }
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(.authTextMuted)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundColor(.authAccent)
                .fontWeight(.semibold)
            }
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Shared Components
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(red: 0.97, green: 0.27, blue: 0.27)) // #F84444
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.97, green: 0.27, blue: 0.27))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.27, green: 0.04, blue: 0.04).opacity(0.5)) // dark red container
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.97, green: 0.27, blue: 0.27).opacity(0.4), lineWidth: 1)
        )
    }
    
    private func successBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.summaryGreen)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.summaryGreen)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.02, green: 0.18, blue: 0.09).opacity(0.5))
        )
    }
    
    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(red: 0.133, green: 0.133, blue: 0.133)) // #222222
                .frame(height: 1)
            Text("або")
                .font(.system(size: 13))
                .foregroundColor(.authTextMuted)
            Rectangle()
                .fill(Color(red: 0.133, green: 0.133, blue: 0.133))
                .frame(height: 1)
        }
    }
    
    private var googleSignInButton: some View {
        Button(action: { viewModel.googleSignIn() }) {
            HStack(spacing: 10) {
                Text("G")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.259, green: 0.522, blue: 0.957)) // #4285F4
                Text("Продовжити з Google")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.authTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.047, green: 0.047, blue: 0.047)) // surface #0C0C0C
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.133, green: 0.133, blue: 0.133), lineWidth: 1) // #222222
            )
        }
    }
    
    private var googleTermsNotice: some View {
        Text("Продовжуючи, ви приймаєте Умови використання та Політику конфіденційності")
            .font(.system(size: 11))
            .foregroundColor(.authTextMuted)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

// MARK: - Auth Colors (matching Android Theme.kt dark scheme)

extension Color {
    // Accent indigo — matches Android Accent #6366F1
    static let authAccent = Color(red: 0.388, green: 0.400, blue: 0.945) // #6366F1
    
    // Dark accent for hover — #4F46E5
    static let authAccentHover = Color(red: 0.310, green: 0.275, blue: 0.898)
    
    // Text colors — matches Android DarkInk #F0EEFF
    static let authTextPrimary = Color(red: 0.941, green: 0.933, blue: 1.0) // #F0EEFF
    
    // Muted text — matches Android DarkMuted #9CA3AF
    static let authTextMuted = Color(red: 0.612, green: 0.639, blue: 0.686) // #9CA3AF
    
    // Dark primary (for dark scheme) — #818CF8
    static let authAccentLight = Color(red: 0.506, green: 0.549, blue: 0.973) // #818CF8
}

// MARK: - Outlined Text Field (matches Android OutlinedTextField)

struct AuthOutlinedField: View {
    @Binding var value: String
    let label: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var showToggle: Bool = false
    var isPasswordVisible: Bool = false
    var onTogglePassword: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    private var borderColor: Color {
        isFocused ? .authAccentLight : Color(red: 0.133, green: 0.133, blue: 0.133) // #222222
    }
    
    private var bgColor: Color {
        isFocused
            ? Color(red: 0.047, green: 0.047, blue: 0.047) // #0C0C0C
            : Color(red: 0.067, green: 0.067, blue: 0.067).opacity(0.4) // surfaceVariant
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.authTextPrimary)
            
            HStack(spacing: 0) {
                if isSecure {
                    SecureField(placeholder, text: $value)
                        .textContentType(.password)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $value)
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                        .focused($isFocused)
                }
                
                if showToggle, let onTogglePassword {
                    Button(action: onTogglePassword) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundColor(.authTextMuted)
                    }
                    .padding(.leading, 8)
                }
            }
            .foregroundColor(.authTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
}

// MARK: - Primary Action Button (matches Android PrimaryButton)

struct PrimaryActionButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isLoading ? Color.authAccent.opacity(0.6) : .authAccent)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Qurio Logo (text-based, matches Android QurioLogo)

struct QurioLogo: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Qurio")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.authTextPrimary)
            Text(".")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.authAccentLight)
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.03
            }
        }
    }
}
