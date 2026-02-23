import StoreKit
import SwiftUI
import Combine

// MARK: - StoreManager

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    // MARK: - Product IDs（需在 App Store Connect 创建）
    static let monthlyID = "com.xinyao.lifevault.pro.monthly"
    static let annualID  = "com.xinyao.lifevault.pro.annual"

    // MARK: - Published State
    @Published var isPro          = false
    @Published var monthlyProduct: Product? = nil
    @Published var annualProduct:  Product? = nil
    @Published var isLoading      = false
    @Published var purchaseError: String? = nil

    private var transactionTask: Task<Void, Never>?

    private init() {
        // 启动时从 UserDefaults 快速恢复（避免闪屏）
        isPro = UserDefaults.standard.bool(forKey: "isPro")
        transactionTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
        }
    }

    deinit { transactionTask?.cancel() }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.monthlyID, Self.annualID])
            monthlyProduct = fetched.first { $0.id == Self.monthlyID }
            annualProduct  = fetched.first { $0.id == Self.annualID }
        } catch {
            print("[StoreKit] 产品加载失败: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshPurchaseStatus()
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlement Check

    func refreshPurchaseStatus() async {
        var proFound = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               (tx.productID == Self.monthlyID || tx.productID == Self.annualID),
               tx.revocationDate == nil {
                proFound = true
                break
            }
        }
        isPro = proFound
        UserDefaults.standard.set(proFound, forKey: "isPro")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await self?.refreshPurchaseStatus()
                    await tx.finish()
                }
            }
        }
    }

    // MARK: - Verify

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "购买验证失败，请重试" }
    }
}
