//
//  SubscriptionStore.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation
import StoreKit

@Observable
class SubscriptionStore {
    // 会员状态
    var isVIP: Bool = false
    var subscriptionType: SubscriptionType = .none
    var expirationDate: Date?
    
    // 免费次数
    var freeUsageCount: Int = 0
    let maxFreeUsage: Int = 1
    
    // 产品信息
    var products: [Product] = []
    var purchaseError: String?
    var isPurchasing: Bool = false
    var isLoadingProducts: Bool = false
    var productLoadError: String?
    
    // 产品ID（需要在App Store Connect配置）
    static let monthlyProductID = "com.contractscanner.monthly"
    static let yearlyProductID = "com.contractscanner.yearly"
    
    private let freeUsageKey = "free_usage_count"
    private let vipStatusKey = "vip_status"
    private let expirationKey = "vip_expiration"
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        loadLocalStatus()
        
        // 监听交易更新
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    // 交易验证失败，忽略
                }
            }
        }
    }
    
    // MARK: - 检查是否可以使用
    var canUseApp: Bool {
        if isVIP { return true }
        return freeUsageCount < maxFreeUsage
    }
    
    var remainingFreeUsage: Int {
        max(0, maxFreeUsage - freeUsageCount)
    }
    
    // MARK: - 使用一次免费次数
    func useFreeQuota() {
        guard !isVIP else { return }
        freeUsageCount += 1
        UserDefaults.standard.set(freeUsageCount, forKey: freeUsageKey)
    }
    
    // MARK: - 加载本地状态
    private func loadLocalStatus() {
        freeUsageCount = UserDefaults.standard.integer(forKey: freeUsageKey)
        isVIP = UserDefaults.standard.bool(forKey: vipStatusKey)
        if let expiration = UserDefaults.standard.object(forKey: expirationKey) as? Date {
            expirationDate = expiration
            if expiration < Date() {
                isVIP = false
            }
        }
    }
    
    // MARK: - 加载产品
    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        productLoadError = nil
        
        do {
            let productIDs = [Self.monthlyProductID, Self.yearlyProductID]
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            
            if products.isEmpty {
                productLoadError = "未找到产品，请检查App Store Connect配置"
            }
        } catch {
            productLoadError = "加载产品失败: \(error.localizedDescription)"
        }
        
        isLoadingProducts = false
    }
    
    // MARK: - 购买
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                isPurchasing = false
                return true
                
            case .userCancelled:
                isPurchasing = false
                return false
                
            case .pending:
                purchaseError = "购买待处理"
                isPurchasing = false
                return false
                
            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            purchaseError = "购买失败: \(error.localizedDescription)"
            isPurchasing = false
            return false
        }
    }
    
    // MARK: - 恢复购买
    @MainActor
    func restorePurchases() async {
        isPurchasing = true
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            purchaseError = "恢复失败: \(error.localizedDescription)"
        }
        isPurchasing = false
    }
    
    // MARK: - 更新订阅状态
    @MainActor
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        var latestExpiration: Date?
        var currentType: SubscriptionType = .none
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.monthlyProductID {
                    hasActiveSubscription = true
                    currentType = .monthly
                    latestExpiration = transaction.expirationDate
                } else if transaction.productID == Self.yearlyProductID {
                    hasActiveSubscription = true
                    currentType = .yearly
                    latestExpiration = transaction.expirationDate
                }
            }
        }
        
        isVIP = hasActiveSubscription
        subscriptionType = currentType
        expirationDate = latestExpiration
        
        UserDefaults.standard.set(isVIP, forKey: vipStatusKey)
        if let exp = expirationDate {
            UserDefaults.standard.set(exp, forKey: expirationKey)
        }
    }
    
    // MARK: - 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - 订阅类型
enum SubscriptionType: String {
    case none = "免费用户"
    case monthly = "月度会员"
    case yearly = "年度会员"
}

// MARK: - 订阅错误
enum SubscriptionError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "交易验证失败"
        }
    }
}
