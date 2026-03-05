import SwiftUI

/// Auth screen — light iOS style matching Android's AuthScreen.kt.
/// Card-based layout with outlined fields, indigo accent, system font.
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    // Light theme colors (matching Android LightColorScheme)
    private let bgColor = Color(red: 0.973, green: 0.980, blue: 1.0)         // #F8FAFF
    private let surfaceColor = Color.white                                      // #FFFFFF
    private let borderColor = Color(red: 0.910, green: 0.910, blue: 0.941)    // #E8E8F0
    private let textPrimary = Color(red: 0.059, green: 0.059, blue: 0.102)    // #0F0F1A
    private let textMuted = Color(red: 0.420, green: 0.447, blue: 0.502)      // #6B7280
    private let accentIndigo = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1
    private let inputBg = Color(red: 0.945, green: 0.953, blue: 0.976)        // #F1F3F9
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    // Logo
                    QuiroLogo(textColor: textPrimary, accentColor: accentIndigo)
                    
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
                            .fill(surfaceColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Login
    
    private var loginContent: some View {
        VStack(spacing: 0) {
            Text("Увійти")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textPrimary)
            
            Spacer().frame(height: 4)
            
            HStack(spacing: 4) {
                Text("Ще немає акаунту?")
                    .foregroundColor(textMuted)
                Button("Створити") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .register
                }
                .foregroundColor(accentIndigo)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            
            Spacer().frame(height: 20)
            
            googleSignInButton
            googleTermsNotice
            
            Spacer().frame(height: 16)
            orDivider
            Spacer().frame(height: 16)
            
            LightAuthField(
                value: $viewModel.loginEmail,
                label: "Електронна пошта",
                placeholder: "alex@email.com",
                keyboardType: .emailAddress,
                labelColor: textPrimary,
                placeholderColor: textMuted,
                bgColor: inputBg,
                borderColor: borderColor,
                accentColor: accentIndigo
            )
            
            Spacer().frame(height: 12)
            
            LightAuthField(
                value: $viewModel.loginPassword,
                label: "Пароль",
                placeholder: "Ваш пароль",
                isSecure: !viewModel.showLoginPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showLoginPassword,
                onTogglePassword: { viewModel.showLoginPassword.toggle() },
                labelColor: textPrimary,
                placeholderColor: textMuted,
                bgColor: inputBg,
                borderColor: borderColor,
                accentColor: accentIndigo
            )
            
            Spacer().frame(height: 20)
            
            LightPrimaryButton("Увійти →", accentColor: accentIndigo, isLoading: viewModel.isLoading) {
                Task { await viewModel.login() }
            }
            
            Spacer().frame(height: 12)
            
            Button("Забули пароль?") {
                viewModel.errorMessage = nil
                viewModel.screenState = .forgotPassword
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(accentIndigo)
        }
    }
    
    // MARK: - Register
    
    private var registerContent: some View {
        VStack(spacing: 0) {
            Text("Створити акаунт")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textPrimary)
            
            Spacer().frame(height: 4)
            
            HStack(spacing: 4) {
                Text("Вже є акаунт?")
                    .foregroundColor(textMuted)
                Button("Увійти") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .login
                }
                .foregroundColor(accentIndigo)
                .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            
            Spacer().frame(height: 20)
            
            googleSignInButton
            googleTermsNotice
            
            Spacer().frame(height: 16)
            orDivider
            Spacer().frame(height: 16)
            
            LightAuthField(value: $viewModel.registerName, label: "Повне ім'я", placeholder: "Олексій Коваль", labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 12)
            
            LightAuthField(value: $viewModel.registerEmail, label: "Електронна пошта", placeholder: "alex@email.com", keyboardType: .emailAddress, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 12)
            
            LightAuthField(value: $viewModel.registerPassword, label: "Пароль", placeholder: "Мінімум 8 символів", isSecure: !viewModel.showRegisterPassword, showToggle: true, isPasswordVisible: viewModel.showRegisterPassword, onTogglePassword: { viewModel.showRegisterPassword.toggle() }, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 12)
            
            LightAuthField(value: $viewModel.registerPassword2, label: "Підтвердіть пароль", placeholder: "Повторіть пароль", isSecure: !viewModel.showRegisterPassword, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 16)
            
            LightPrimaryButton("Створити акаунт →", accentColor: accentIndigo, isLoading: viewModel.isLoading) {
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
                .foregroundColor(textPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Ми надіслали 6-значний код на\n\(viewModel.verifyEmail)")
                .font(.system(size: 14))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            LightAuthField(value: $viewModel.verifyCode, label: "Код підтвердження", placeholder: "000000", keyboardType: .numberPad, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 20)
            
            LightPrimaryButton("Підтвердити →", accentColor: accentIndigo, isLoading: viewModel.isLoading) {
                Task { await viewModel.verify() }
            }
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(textMuted)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundColor(accentIndigo)
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
                .foregroundColor(textPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Введіть email, і ми надішлемо\nкод для скидання паролю.")
                .font(.system(size: 14))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            LightAuthField(value: $viewModel.forgotEmail, label: "Електронна пошта", placeholder: "alex@email.com", keyboardType: .emailAddress, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 20)
            
            LightPrimaryButton("Надіслати код →", accentColor: accentIndigo, isLoading: viewModel.isLoading) {
                Task { await viewModel.forgotPassword() }
            }
            
            Spacer().frame(height: 16)
            
            Button("← Повернутись до входу") {
                viewModel.errorMessage = nil
                viewModel.screenState = .login
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(accentIndigo)
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
                .foregroundColor(textPrimary)
            
            Spacer().frame(height: 8)
            
            Text("Введіть код з листа та новий пароль")
                .font(.system(size: 14))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 24)
            
            LightAuthField(value: $viewModel.resetCode, label: "Код з листа", placeholder: "123456", keyboardType: .numberPad, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 12)
            
            LightAuthField(value: $viewModel.resetPassword, label: "Новий пароль", placeholder: "Мінімум 8 символів", isSecure: !viewModel.showResetPassword, showToggle: true, isPasswordVisible: viewModel.showResetPassword, onTogglePassword: { viewModel.showResetPassword.toggle() }, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 12)
            
            LightAuthField(value: $viewModel.resetPassword2, label: "Підтвердіть пароль", placeholder: "Повторіть пароль", isSecure: !viewModel.showResetPassword, labelColor: textPrimary, placeholderColor: textMuted, bgColor: inputBg, borderColor: borderColor, accentColor: accentIndigo)
            
            Spacer().frame(height: 20)
            
            LightPrimaryButton("Скинути пароль →", accentColor: accentIndigo, isLoading: viewModel.isLoading) {
                Task { await viewModel.doResetPassword() }
            }
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(textMuted)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundColor(accentIndigo)
                .fontWeight(.semibold)
            }
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Shared Components
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.996, green: 0.949, blue: 0.949)) // #FEF2F2
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.3), lineWidth: 1)
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
                .fill(Color(red: 0.926, green: 0.992, blue: 0.961)) // #ECFDF5
        )
    }
    
    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(borderColor)
                .frame(height: 1)
            Text("або")
                .font(.system(size: 13))
                .foregroundColor(textMuted)
            Rectangle()
                .fill(borderColor)
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
                    .foregroundColor(textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
    
    private var googleTermsNotice: some View {
        Text("Продовжуючи, ви приймаєте Умови використання та Політику конфіденційності")
            .font(.system(size: 11))
            .foregroundColor(textMuted)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

// MARK: - Quiro Logo

struct QuiroLogo: View {
    var textColor: Color = .black
    var accentColor: Color = Color(red: 0.388, green: 0.400, blue: 0.945)
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Quiro")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(textColor)
            Text(".")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(accentColor)
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

// MARK: - Light Auth Text Field

struct LightAuthField: View {
    @Binding var value: String
    let label: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var showToggle: Bool = false
    var isPasswordVisible: Bool = false
    var onTogglePassword: (() -> Void)? = nil
    
    var labelColor: Color
    var placeholderColor: Color
    var bgColor: Color
    var borderColor: Color
    var accentColor: Color
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(labelColor)
            
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
                            .foregroundColor(placeholderColor)
                    }
                    .padding(.leading, 8)
                }
            }
            .foregroundColor(labelColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFocused ? Color.white : bgColor.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
}

// MARK: - Light Primary Button

struct LightPrimaryButton: View {
    let title: String
    let accentColor: Color
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, accentColor: Color, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.accentColor = accentColor
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
                    .fill(isLoading ? accentColor.opacity(0.6) : accentColor)
            )
        }
        .disabled(isLoading)
    }
}
