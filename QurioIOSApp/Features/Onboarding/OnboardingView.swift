import SwiftUI

/// Onboarding tutorial mirroring OnboardingScreen.kt (944 lines).
/// 13-step interactive tutorial with study material pages.
struct OnboardingView: View {
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @Environment(\.appTheme) var theme
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Ласкаво просимо!",
            subtitle: "Quiro — твій AI-асистент для навчання",
            icon: "brain.head.profile",
            description: "Quiro допомагає тобі з домашніми завданнями, тестами та підготовкою до іспитів. Просто зроби скріншот — і отримай відповідь!",
            color: .accentPurple
        ),
        OnboardingStep(
            title: "Як це працює?",
            subtitle: "Крок 1: Запусти Quiro",
            icon: "play.circle.fill",
            description: "Натисни кнопку «Запустити Quiro» на головному екрані. З'явиться плаваюча панель (Dynamic Island) зверху екрану.",
            color: .accentPurple
        ),
        OnboardingStep(
            title: "Плаваюча панель",
            subtitle: "Крок 2: Панель Quiro",
            icon: "rectangle.portrait.on.rectangle.portrait",
            description: "Панель відображається зверху екрану і доступна з будь-якого додатку. Вона має стани: Готовий, Зйомка, Думаю, Відповідь.",
            color: .violet
        ),
        OnboardingStep(
            title: "Зйомка екрану",
            subtitle: "Крок 3: Зроби скріншот",
            icon: "camera.fill",
            description: "Відкрий питання в будь-якому додатку (підручник, тест, PDF) і натисни кнопку 📸 на панелі Quiro. AI проаналізує скріншот і дасть відповідь.",
            color: .summaryGreen
        ),
        OnboardingStep(
            title: "Відповідь AI",
            subtitle: "Крок 4: Отримай відповідь",
            icon: "lightbulb.fill",
            description: "Quiro покаже правильну відповідь з поясненням. Ти можеш скопіювати текст або поскаржитись, якщо відповідь неправильна.",
            color: .yellowDot
        ),
        OnboardingStep(
            title: "Власне питання",
            subtitle: "Крок 5: Запитай сам",
            icon: "text.bubble.fill",
            description: "Натисни «✏️ Своє питання» і введи будь-яке запитання. AI відповість на основі скріншота та твого тексту.",
            color: .accentPurple
        ),
        OnboardingStep(
            title: "Конспекти",
            subtitle: "Крок 6: Створюй конспекти",
            icon: "doc.text.fill",
            description: "Зроби 1-5 скріншотів навчального матеріалу і Quiro створить структурований конспект. Доступно для Pro користувачів.",
            color: .summaryGreen
        ),
        OnboardingStep(
            title: "Тести",
            subtitle: "Крок 7: Перевір знання",
            icon: "checkmark.circle.fill",
            description: "З конспекту можна одразу згенерувати тест! Quiro створить запитання з варіантами відповідей і покаже результат.",
            color: .violet
        ),
        OnboardingStep(
            title: "Серія навчання",
            subtitle: "Крок 8: Будуй серію!",
            icon: "flame.fill",
            description: "Використовуй Quiro кожен день і отримуй нагороди! За серію 7 днів — 5 днів Pro безкоштовно. За 30 днів — цілий тиждень Pro!",
            color: .streakOrange
        ),
        OnboardingStep(
            title: "Історія",
            subtitle: "Крок 9: Зберігай все",
            icon: "clock.arrow.circlepath",
            description: "Всі питання та відповіді зберігаються в Історії. Можеш переглядати, шукати та експортувати в PDF.",
            color: .accentPurple
        ),
        OnboardingStep(
            title: "Приватність",
            subtitle: "Крок 10: Твої дані захищені",
            icon: "lock.shield.fill",
            description: "Quiro використовує скріншоти ТІЛЬКИ для аналізу AI. Зображення не зберігаються на серверах. Увімкни Режим приватності для повної анонімності.",
            color: .accentPurple
        ),
        OnboardingStep(
            title: "Pro план",
            subtitle: "Крок 11: Більше можливостей",
            icon: "crown.fill",
            description: "Pro план дає:\n• Необмежені запити\n• Конспекти (до 3/день)\n• Тести з конспектів\n• Пріоритетну підтримку",
            color: .yellowDot
        ),
        OnboardingStep(
            title: "Готово!",
            subtitle: "Ти готовий навчатися з Quiro!",
            icon: "rocket.fill",
            description: "Натисни «Почати» і спробуй свій перший запит. Залишилось 10 безкоштовних запитів для тестування. Успіхів! 🎉",
            color: .accentPurple
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.darkSurface, steps[currentStep].color.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut, value: currentStep)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Пропустити") { onSkip() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding()
                }
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(spacing: 24) {
                            Spacer()
                            
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(step.color.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: step.icon)
                                    .font(.system(size: 44))
                                    .foregroundColor(step.color)
                            }
                            
                            // Title
                            Text(step.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(step.subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                            
                            // Description
                            Text(step.description)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? steps[currentStep].color : Color.white.opacity(0.2))
                            .frame(width: i == currentStep ? 10 : 6, height: i == currentStep ? 10 : 6)
                            .animation(.easeInOut(duration: 0.2), value: currentStep)
                    }
                }
                .padding(.bottom, 20)
                
                // Buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        OutlinedButton("← Назад") {
                            withAnimation { currentStep -= 1 }
                        }
                    }
                    
                    if currentStep < steps.count - 1 {
                        AccentButton("Далі →") {
                            withAnimation { currentStep += 1 }
                        }
                    } else {
                        AccentButton("🚀 Почати!", icon: "arrow.right") {
                            onComplete()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Step Model

struct OnboardingStep {
    let title: String
    let subtitle: String
    let icon: String
    let description: String
    let color: Color
}
