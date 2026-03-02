import SwiftUI

/// Auth screen mirroring AuthScreen.kt (1023 lines).
/// Login/Register/Verify/ForgotPassword/ResetPassword with glass aesthetic.
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.darkSurface, Color(red: 0.15, green: 0.1, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    // Logo
                    QurioLogo()
                    
                    // Error / Success messages
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.accentRed)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.accentRed)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    if let success = viewModel.successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.summaryGreen)
                            Text(success)
                                .font(.system(size: 14))
                                .foregroundColor(.summaryGreen)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.summaryGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Login
    
    private var loginContent: some View {
        VStack(spacing: 16) {
            Text("Увійти")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Введіть дані для входу")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer().frame(height: 8)
            
            AuthInputField(
                value: $viewModel.loginEmail,
                label: "Email",
                placeholder: "your@email.com",
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            AuthInputField(
                value: $viewModel.loginPassword,
                label: "Пароль",
                placeholder: "••••••••",
                icon: "lock",
                isSecure: !viewModel.showLoginPassword,
                trailingIcon: viewModel.showLoginPassword ? "eye.slash" : "eye",
                onTrailingTap: { viewModel.showLoginPassword.toggle() }
            )
            
            HStack {
                Spacer()
                Button("Забув пароль?") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .forgotPassword
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentPurple)
            }
            
            AccentButton("Увійти", icon: "arrow.right", isLoading: viewModel.isLoading) {
                Task { await viewModel.login() }
            }
            
            orDivider
            
            googleSignInButton
            
            Spacer().frame(height: 8)
            
            HStack(spacing: 4) {
                Text("Немає акаунту?")
                    .foregroundColor(.white.opacity(0.6))
                Button("Зареєструватися") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .register
                }
                .foregroundColor(.accentPurple)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
        }
    }
    
    // MARK: - Register
    
    private var registerContent: some View {
        VStack(spacing: 16) {
            Text("Реєстрація")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Створіть акаунт")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer().frame(height: 8)
            
            AuthInputField(
                value: $viewModel.registerName,
                label: "Ім'я",
                placeholder: "Ваше ім'я",
                icon: "person"
            )
            
            AuthInputField(
                value: $viewModel.registerEmail,
                label: "Email",
                placeholder: "your@email.com",
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            AuthInputField(
                value: $viewModel.registerPassword,
                label: "Пароль",
                placeholder: "Мінімум 6 символів",
                icon: "lock",
                isSecure: !viewModel.showRegisterPassword,
                trailingIcon: viewModel.showRegisterPassword ? "eye.slash" : "eye",
                onTrailingTap: { viewModel.showRegisterPassword.toggle() }
            )
            
            AuthInputField(
                value: $viewModel.registerPassword2,
                label: "Повторіть пароль",
                placeholder: "Повторіть пароль",
                icon: "lock",
                isSecure: !viewModel.showRegisterPassword
            )
            
            AccentButton("Зареєструватися", icon: "person.badge.plus", isLoading: viewModel.isLoading) {
                Task { await viewModel.register() }
            }
            
            orDivider
            
            googleSignInButton
            
            Spacer().frame(height: 8)
            
            HStack(spacing: 4) {
                Text("Вже є акаунт?")
                    .foregroundColor(.white.opacity(0.6))
                Button("Увійти") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .login
                }
                .foregroundColor(.accentPurple)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            
            // Google terms notice
            Text("Натискаючи «Увійти через Google», ви погоджуєтесь з Умовами використання та Політикою конфіденційності Google.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Verify
    
    private var verifyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(.accentPurple)
            
            Text("Підтвердження Email")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Введіть код, надісланий на\n\(viewModel.verifyEmail)")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            AuthInputField(
                value: $viewModel.verifyCode,
                label: "Код підтвердження",
                placeholder: "123456",
                icon: "number",
                keyboardType: .numberPad
            )
            
            AccentButton("Підтвердити", icon: "checkmark.circle", isLoading: viewModel.isLoading) {
                Task { await viewModel.verify() }
            }
            
            Button("Надіслати код повторно") {
                Task { await viewModel.resendCode() }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.accentPurple)
        }
    }
    
    // MARK: - Forgot Password
    
    private var forgotPasswordContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "key")
                .font(.system(size: 48))
                .foregroundColor(.accentPurple)
            
            Text("Відновлення пароля")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Введіть email для отримання коду скидання")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            AuthInputField(
                value: $viewModel.forgotEmail,
                label: "Email",
                placeholder: "your@email.com",
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            AccentButton("Надіслати код", icon: "paperplane", isLoading: viewModel.isLoading) {
                Task { await viewModel.forgotPassword() }
            }
            
            Button("Назад до входу") {
                viewModel.errorMessage = nil
                viewModel.screenState = .login
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.accentPurple)
        }
    }
    
    // MARK: - Reset Password
    
    private var resetPasswordContent: some View {
        VStack(spacing: 16) {
            Text("Новий пароль")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Введіть код та новий пароль")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            
            AuthInputField(
                value: $viewModel.resetCode,
                label: "Код скидання",
                placeholder: "123456",
                icon: "number",
                keyboardType: .numberPad
            )
            
            AuthInputField(
                value: $viewModel.resetPassword,
                label: "Новий пароль",
                placeholder: "Мінімум 6 символів",
                icon: "lock",
                isSecure: !viewModel.showResetPassword,
                trailingIcon: viewModel.showResetPassword ? "eye.slash" : "eye",
                onTrailingTap: { viewModel.showResetPassword.toggle() }
            )
            
            AuthInputField(
                value: $viewModel.resetPassword2,
                label: "Повторіть пароль",
                placeholder: "Повторіть пароль",
                icon: "lock",
                isSecure: !viewModel.showResetPassword
            )
            
            AccentButton("Скинути пароль", icon: "checkmark.shield", isLoading: viewModel.isLoading) {
                Task { await viewModel.doResetPassword() }
            }
            
            Button("Надіслати код повторно") {
                Task { await viewModel.resendCode() }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.accentPurple)
        }
    }
    
    // MARK: - Shared Components
    
    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
            Text("або")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
    }
    
    private var googleSignInButton: some View {
        Button(action: { viewModel.googleSignIn() }) {
            HStack(spacing: 10) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                Text("Увійти через Google")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Auth Input Field

struct AuthInputField: View {
    @Binding var value: String
    let label: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var trailingIcon: String? = nil
    var onTrailingTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $value)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $value)
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                }
                
                if let trailingIcon, let onTrailingTap {
                    Button(action: onTrailingTap) {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
}

// MARK: - Qurio Logo

struct QurioLogo: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentPurple, .violet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("Qurio")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("AI-асистент для навчання")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.bottom, 8)
    }
}
