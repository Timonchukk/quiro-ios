import SwiftUI

/// Fix 3: Full-screen consent view shown before opening broadcast picker.
/// Explains what data is captured, where it goes, and how to stop.
struct CaptureConsentView: View {
    @ObservedObject var privacyManager = PrivacyManager.shared
    @Environment(\.appTheme) var theme

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Shield icon
                ZStack {
                    Circle()
                        .fill(Color.accentPurple.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundColor(.accentPurple)
                }

                Text("Дозвіл на запис екрану")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Consent points
                VStack(alignment: .leading, spacing: 16) {
                    consentPoint(
                        icon: "rectangle.inset.filled.and.person.filled",
                        title: "Запис всього екрану",
                        detail: "Після підтвердження iOS почне запис вмісту всього екрану, включно з іншими додатками."
                    )

                    consentPoint(
                        icon: "icloud.and.arrow.up",
                        title: "Передача на AI сервер",
                        detail: "Знімки екрану надсилаються на сервер Quiro для аналізу AI. Вони НЕ зберігаються після обробки."
                    )

                    consentPoint(
                        icon: "hand.raised.fill",
                        title: "Повний контроль",
                        detail: "Ви можете зупинити запис у будь-який час через панель Quiro або Центр керування iOS."
                    )

                    consentPoint(
                        icon: "lock.shield.fill",
                        title: "Конфіденційне оброблення",
                        detail: "Кадри обробляються з мінімальною якістю, необхідною для AI. Конфіденційні дані не зберігаються."
                    )
                }
                .padding(.horizontal, 8)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    AccentButton("✅ Я розумію, продовжити", icon: "checkmark.shield") {
                        privacyManager.grantConsent()
                    }

                    Button(action: {
                        privacyManager.denyConsent()
                    }) {
                        Text("Скасувати")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Consent Point Row

    private func consentPoint(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentPurple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
