import SwiftUI
import Combine

/// Auth view model mirroring AuthViewModel.kt.
/// State machine: login → register → verify → forgotPassword → resetPassword
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var screenState: AuthScreenState = .login
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Login fields
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var showLoginPassword = false
    
    // Register fields
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerPassword2 = ""
    @Published var showRegisterPassword = false
    
    // Verify fields
    @Published var verifyEmail = ""
    @Published var verifyCode = ""
    
    // Forgot/Reset fields
    @Published var forgotEmail = ""
    @Published var resetCode = ""
    @Published var resetPassword = ""
    @Published var resetPassword2 = ""
    @Published var showResetPassword = false
    
    private let authRepo = AuthRepository.shared
    private let settings = SettingsRepository.shared
    
    // MARK: - Login
    
    func login() async {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Введіть email та пароль"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.login(email: loginEmail, password: loginPassword)
            // Sync after login
            try? await authRepo.syncSettings()
            await HistoryRepository.shared.syncFromServer()
        } catch let error as AuthRepository.AuthError {
            if error.needsVerification {
                verifyEmail = error.email ?? loginEmail
                screenState = .verify
            } else {
                errorMessage = error.message
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Register
    
    func register() async {
        guard !registerName.isEmpty else { errorMessage = "Введіть ім'я"; return }
        guard !registerEmail.isEmpty else { errorMessage = "Введіть email"; return }
        guard registerPassword.count >= 6 else { errorMessage = "Пароль має бути мінімум 6 символів"; return }
        guard registerPassword == registerPassword2 else { errorMessage = "Паролі не збігаються"; return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.register(name: registerName, email: registerEmail, password: registerPassword)
            verifyEmail = registerEmail
            screenState = .verify
            successMessage = "Код підтвердження надіслано на \(registerEmail)"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Verify
    
    func verify() async {
        guard verifyCode.count >= 4 else { errorMessage = "Введіть код підтвердження"; return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.verifyEmail(email: verifyEmail, code: verifyCode)
            try? await authRepo.syncSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func resendCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.resendCode(email: verifyEmail)
            successMessage = "Код повторно надіслано"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Forgot Password
    
    func forgotPassword() async {
        guard !forgotEmail.isEmpty else { errorMessage = "Введіть email"; return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.forgotPassword(email: forgotEmail)
            screenState = .resetPassword
            verifyEmail = forgotEmail
            successMessage = "Код скидання надіслано на \(forgotEmail)"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Reset Password
    
    func doResetPassword() async {
        guard !resetCode.isEmpty else { errorMessage = "Введіть код"; return }
        guard resetPassword.count >= 6 else { errorMessage = "Пароль має бути мінімум 6 символів"; return }
        guard resetPassword == resetPassword2 else { errorMessage = "Паролі не збігаються"; return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepo.resetPassword(email: verifyEmail, code: resetCode, newPassword: resetPassword)
            try? await authRepo.syncSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign-In
    
    func googleSignIn() {
        // TODO: Implement Google Sign-In SDK integration
        errorMessage = "Google Sign-In буде доступний незабаром"
    }
}
