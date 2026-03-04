import Foundation
import StoreKit
import Combine

/// StoreKit 2 integration mirroring BillingManager.kt.
/// Handles Free vs Pro subscription management.
@MainActor
final class InAppPurchaseService: ObservableObject {
    static let shared = InAppPurchaseService()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    private var updateTask: Task<Void, Never>?
    private let settings = SettingsRepository.shared
    
    private let productIDs = [Config.proMonthlyProductID, Config.proYearlyProductID]
    
    private init() {
        updateTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
        Task { await updateSubscriptionStatus() }
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Set(productIDs))
                .sorted { $0.price < $1.price }
        } catch {
            print("InAppPurchase: Failed to load products: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Check Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasActive = false
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if productIDs.contains(transaction.productID) {
                    hasActive = true
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }
        
        // Also check reward Pro
        if settings.hasRewardPro() {
            hasActive = true
        }
        
        // IMPORTANT: Only UPGRADE to Pro from StoreKit, never DOWNGRADE.
        // The server may have set hasActiveSubscription=true (e.g. Android/admin subscription).
        // StoreKit should not override server-synced Pro status.
        if hasActive {
            settings.hasActiveSubscription = true
        }
        // If StoreKit says false, keep whatever the server said — don't reset.
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helpers
    
    var isPro: Bool {
        settings.hasActiveSubscription
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == Config.proMonthlyProductID }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == Config.proYearlyProductID }
    }
}
