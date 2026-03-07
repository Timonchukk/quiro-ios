import SwiftUI

// MARK: - Liquid Glass Auth Screen

/// Auth screen — Liquid Glass design with segmented control and 3D flip.
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var activeTab: AuthTab = .signIn
    @State private var isFlipping = false
    @State private var flipAngle: Double = 0
    @State private var showContent = true
    
    enum AuthTab: Int, CaseIterable {
        case signIn = 0
        case createAccount = 1
        
        var title: String {
            switch self {
            case .signIn: return "Увійти"
            case .createAccount: return "Створити акаунт"
            }
        }
    }
    
    // Color palette — blue/cyan accent (matches Theme.swift)
    private let accentBlue = Color(red: 0.20, green: 0.49, blue: 0.96)   // #337DF5
    private let accentSky  = Color(red: 0.33, green: 0.67, blue: 0.98)   // #54ABFA
    private var accentGradient: LinearGradient {
        LinearGradient(colors: [accentBlue, accentSky], startPoint: .leading, endPoint: .trailing)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 70)
                    
                    // Glass card
                    glassCard
                    
                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 20)
            }
        }
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.94, blue: 0.98),
                    Color(red: 0.90, green: 0.91, blue: 0.97),
                    Color(red: 0.93, green: 0.93, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Accent glow circles
            Circle()
                .fill(accentBlue.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(accentSky.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 120, y: 300)
        }
    }
    
    // MARK: - Glass Card
    
    private var glassCard: some View {
        VStack(spacing: 0) {
            // Header
            cardHeader
                .padding(.bottom, 24)
            
            // Segmented control
            segmentedControl
                .padding(.bottom, 24)
            
            // Error / Success
            if let error = viewModel.errorMessage {
                errorBanner(message: error)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            if let success = viewModel.successMessage {
                successBanner(message: success)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Handle special states
            if viewModel.screenState == .verify {
                verifyContent
                    .transition(.opacity)
            } else if viewModel.screenState == .forgotPassword {
                forgotPasswordContent
                    .transition(.opacity)
            } else if viewModel.screenState == .resetPassword {
                resetPasswordContent
                    .transition(.opacity)
            } else {
                // Main content with 3D flip
                ZStack {
                    if showContent {
                        Group {
                            if activeTab == .signIn {
                                signInFields
                            } else {
                                registerFields
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))
            }
            
            // Terms
            termsNotice
                .padding(.top, 20)
        }
        .padding(24)
        .background(glassBackground)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage != nil)
        .animation(.easeInOut(duration: 0.25), value: viewModel.successMessage != nil)
        .animation(.easeInOut(duration: 0.3), value: viewModel.screenState)
    }
    
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.white.opacity(0.78))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
            .shadow(color: accentBlue.opacity(0.05), radius: 40, y: 20)
    }
    
    // MARK: - Card Header
    
    private var cardHeader: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Text("Quiro")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                Text(".")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(accentGradient)
            }
            
            Text("Ваш AI-помічник")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.rawValue) { tab in
                Button {
                    guard tab != activeTab, !isFlipping else { return }
                    flipToTab(tab)
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(.system(size: 15, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundColor(activeTab == tab ? Color(red: 0.1, green: 0.1, blue: 0.15) : .secondary)
                            .frame(maxWidth: .infinity)
                        
                        // Indicator bar
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(activeTab == tab ? AnyShapeStyle(accentGradient) : AnyShapeStyle(Color.clear))
                            .frame(height: 3)
                    }
                }
                .buttonStyle(MicroPressStyle())
            }
        }
    }
    
    // MARK: - 3D Flip Animation
    
    private func flipToTab(_ newTab: AuthTab) {
        isFlipping = true
        viewModel.errorMessage = nil
        viewModel.successMessage = nil
        
        // First half: flip to 90° and hide content
        withAnimation(.easeIn(duration: 0.2)) {
            flipAngle = 90
            showContent = false
        }
        
        // At midpoint: switch content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeTab = newTab
            if newTab == .signIn {
                viewModel.screenState = .login
            } else {
                viewModel.screenState = .register
            }
            
            // Second half: flip from -90° back to 0°
            flipAngle = -90
            showContent = true
            withAnimation(.easeOut(duration: 0.2)) {
                flipAngle = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isFlipping = false
            }
        }
    }
    
    // MARK: - Sign In Fields
    
    private var signInFields: some View {
        VStack(spacing: 0) {
            // Google button
            googleButton
            
            Spacer().frame(height: 20)
            orDivider
            Spacer().frame(height: 20)
            
            // Email
            AuthTextField(
                value: $viewModel.loginEmail,
                label: "Електронна пошта",
                placeholder: "email@example.com",
                keyboardType: .emailAddress,
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 14)
            
            // Password
            AuthTextField(
                value: $viewModel.loginPassword,
                label: "Пароль",
                placeholder: "Ваш пароль",
                isSecure: !viewModel.showLoginPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showLoginPassword,
                onToggle: { viewModel.showLoginPassword.toggle() },
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 10)
            
            // Forgot password
            HStack {
                Spacer()
                Button("Забули пароль?") {
                    viewModel.errorMessage = nil
                    viewModel.screenState = .forgotPassword
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accentGradient)
            }
            
            Spacer().frame(height: 20)
            
            // Sign in button
            AuthGradientButton("Увійти", gradient: accentGradient, isLoading: viewModel.isLoading) {
                Task { await viewModel.login() }
            }
        }
    }
    
    // MARK: - Register Fields
    
    private var registerFields: some View {
        VStack(spacing: 0) {
            // Google button
            googleButton
            
            Spacer().frame(height: 20)
            orDivider
            Spacer().frame(height: 20)
            
            AuthTextField(
                value: $viewModel.registerName,
                label: "Повне ім'я",
                placeholder: "Олексій Коваль",
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 14)
            
            AuthTextField(
                value: $viewModel.registerEmail,
                label: "Електронна пошта",
                placeholder: "email@example.com",
                keyboardType: .emailAddress,
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 14)
            
            AuthTextField(
                value: $viewModel.registerPassword,
                label: "Пароль",
                placeholder: "Мінімум 8 символів",
                isSecure: !viewModel.showRegisterPassword,
                showToggle: true,
                isPasswordVisible: viewModel.showRegisterPassword,
                onToggle: { viewModel.showRegisterPassword.toggle() },
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 14)
            
            AuthTextField(
                value: $viewModel.registerPassword2,
                label: "Підтвердіть пароль",
                placeholder: "Повторіть пароль",
                isSecure: !viewModel.showRegisterPassword,
                accentColor: accentBlue
            )
            
            Spacer().frame(height: 20)
            
            AuthGradientButton("Створити акаунт", gradient: accentGradient, isLoading: viewModel.isLoading) {
                Task { await viewModel.register() }
            }
        }
    }
    
    // MARK: - Verify
    
    private var verifyContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 36))
                .foregroundStyle(accentGradient)
                .symbolRenderingMode(.hierarchical)
            
            Spacer().frame(height: 14)
            
            Text("Підтвердіть email")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            Spacer().frame(height: 8)
            
            Text("Ми надіслали 6-значний код на\n\(viewModel.verifyEmail)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            AuthTextField(value: $viewModel.verifyCode, label: "Код підтвердження", placeholder: "000000", keyboardType: .numberPad, accentColor: accentBlue)
            
            Spacer().frame(height: 20)
            
            AuthGradientButton("Підтвердити", gradient: accentGradient, isLoading: viewModel.isLoading) {
                Task { await viewModel.verify() }
            }
            
            Spacer().frame(height: 14)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(.secondary)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundStyle(accentGradient)
                .fontWeight(.semibold)
            }
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Forgot Password
    
    private var forgotPasswordContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "key.fill")
                .font(.system(size: 36))
                .foregroundStyle(accentGradient)
                .symbolRenderingMode(.hierarchical)
            
            Spacer().frame(height: 14)
            
            Text("Забули пароль?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            Spacer().frame(height: 8)
            
            Text("Введіть email, і ми надішлемо\nкод для скидання паролю.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer().frame(height: 24)
            
            AuthTextField(value: $viewModel.forgotEmail, label: "Електронна пошта", placeholder: "email@example.com", keyboardType: .emailAddress, accentColor: accentBlue)
            
            Spacer().frame(height: 20)
            
            AuthGradientButton("Надіслати код", gradient: accentGradient, isLoading: viewModel.isLoading) {
                Task { await viewModel.forgotPassword() }
            }
            
            Spacer().frame(height: 14)
            
            Button {
                viewModel.errorMessage = nil
                viewModel.screenState = .login
                activeTab = .signIn
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Повернутись до входу")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentGradient)
            }
        }
    }
    
    // MARK: - Reset Password
    
    private var resetPasswordContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 36))
                .foregroundStyle(accentGradient)
                .symbolRenderingMode(.hierarchical)
            
            Spacer().frame(height: 14)
            
            Text("Новий пароль")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            Spacer().frame(height: 8)
            
            Text("Введіть код з листа та новий пароль")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 24)
            
            AuthTextField(value: $viewModel.resetCode, label: "Код з листа", placeholder: "123456", keyboardType: .numberPad, accentColor: accentBlue)
            Spacer().frame(height: 14)
            AuthTextField(value: $viewModel.resetPassword, label: "Новий пароль", placeholder: "Мінімум 8 символів", isSecure: !viewModel.showResetPassword, showToggle: true, isPasswordVisible: viewModel.showResetPassword, onToggle: { viewModel.showResetPassword.toggle() }, accentColor: accentBlue)
            Spacer().frame(height: 14)
            AuthTextField(value: $viewModel.resetPassword2, label: "Підтвердіть пароль", placeholder: "Повторіть пароль", isSecure: !viewModel.showResetPassword, accentColor: accentBlue)
            
            Spacer().frame(height: 20)
            
            AuthGradientButton("Скинути пароль", gradient: accentGradient, isLoading: viewModel.isLoading) {
                Task { await viewModel.doResetPassword() }
            }
            
            Spacer().frame(height: 14)
            
            HStack(spacing: 4) {
                Text("Не отримали?")
                    .foregroundColor(.secondary)
                Button("Надіслати ще раз") {
                    Task { await viewModel.resendCode() }
                }
                .foregroundStyle(accentGradient)
                .fontWeight(.semibold)
            }
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Shared Components
    
    private var googleButton: some View {
        Button(action: { viewModel.googleSignIn() }) {
            HStack(spacing: 12) {
                // Google "G" multicolor
                Text("G")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.259, green: 0.522, blue: 0.957),
                                Color(red: 0.859, green: 0.263, blue: 0.216),
                                Color(red: 0.957, green: 0.737, blue: 0.184),
                                Color(red: 0.204, green: 0.659, blue: 0.325)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Продовжити з Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        }
        .buttonStyle(MicroPressStyle())
    }
    
    private var orDivider: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
            Text("або")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.75, green: 0.15, blue: 0.15))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.07))
        )
    }
    
    private func successBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.1, green: 0.55, blue: 0.35))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.green.opacity(0.07))
        )
    }
    
    private var termsNotice: some View {
        Text("Продовжуючи, ви приймаєте [Умови використання](https://example.com) та [Політику конфіденційності](https://example.com)")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .tint(accentBlue)
    }
}

// MARK: - Glass Text Field

struct AuthTextField: View {
    @Binding var value: String
    let label: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var showToggle: Bool = false
    var isPasswordVisible: Bool = false
    var onToggle: (() -> Void)? = nil
    var accentColor: Color = .blue
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
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
                
                if showToggle, let onToggle {
                    Button(action: onToggle) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                }
            }
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isFocused ? .white : Color(red: 0.96, green: 0.96, blue: 0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused ? accentColor.opacity(0.6) : Color.black.opacity(0.06),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
            )
            .shadow(color: isFocused ? accentColor.opacity(0.08) : .clear, radius: 8, y: 2)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
}

// MARK: - Accent Gradient Button

struct AuthGradientButton: View {
    let title: String
    let gradient: LinearGradient
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, gradient: LinearGradient, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.gradient = gradient
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradient)
                    .opacity(isLoading ? 0.5 : 1.0)
            )
            .shadow(color: Color(red: 0.20, green: 0.49, blue: 0.96).opacity(isLoading ? 0 : 0.3), radius: 12, y: 6)
        }
        .disabled(isLoading)
        .buttonStyle(MicroPressStyle())
    }
}

// MARK: - Micro Press Button Style

struct MicroPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Keep LightPrimaryButton for compatibility

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
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(isLoading ? accentColor.opacity(0.6) : accentColor))
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}
