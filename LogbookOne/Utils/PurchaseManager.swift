import Foundation
import Security
import UIKit

// Feature gates that can be unlocked with Pro
enum ProFeature: String, CaseIterable {
    case tasks
    case payments
    case clients
    case nagMode
    case export
    case dataImport
}

class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    // Published values to trigger UI updates
    @Published var isPro: Bool = false
    @Published var subscriptionType: SubscriptionType = .none
    @Published var isTestMode: Bool = false
    
    // Constants
    private let keyPrefix = "com.logbookone."
    private let monthlyPrice = "$4.99"
    private let yearlyPrice = "$50"
    private let lifetimePrice = "$125"
    private let testCouponCode = "tester1234"
    
    // URLs for Gumroad/Stripe purchase
    private let monthlySubscriptionURL = "https://example.com/subscribe/monthly"
    private let yearlySubscriptionURL = "https://example.com/subscribe/yearly"
    private let lifetimeSubscriptionURL = "https://example.com/purchase/lifetime"
    
    // Initialize and load saved state
    private init() {
        loadSubscriptionState()
    }
    
    // Subscription types
    enum SubscriptionType: String {
        case none
        case monthly
        case yearly
        case lifetime
    }
    
    // MARK: - Public Methods
    
    // Check if user has access to specific feature
    func hasAccess(to feature: ProFeature) -> Bool {
        // Free features are always accessible
        switch feature {
        case .tasks, .payments, .clients, .nagMode, .export, .dataImport:
            return isPro || isTestMode
        }
    }
    
    // Apply a coupon code
    func applyCoupon(_ code: String) -> Bool {
        if code == testCouponCode {
            isTestMode = true
            saveSubscriptionState()
            return true
        }
        return false // Invalid code
    }
    
    // Update subscription status (call after successful purchase)
    func updateSubscription(type: SubscriptionType) {
        subscriptionType = type
        isPro = (type != .none)
        saveSubscriptionState()
    }
    
    // Get purchase URL based on subscription type
    func getPurchaseURL(for type: SubscriptionType) -> URL? {
        switch type {
        case .monthly:
            return URL(string: monthlySubscriptionURL)
        case .yearly:
            return URL(string: yearlySubscriptionURL)
        case .lifetime:
            return URL(string: lifetimeSubscriptionURL)
        case .none:
            return nil
        }
    }
    
    // Get formatted price for subscription type
    func getPrice(for type: SubscriptionType) -> String {
        switch type {
        case .monthly:
            return monthlyPrice + "/month"
        case .yearly:
            return yearlyPrice + "/year"
        case .lifetime:
            return lifetimePrice
        case .none:
            return ""
        }
    }
    
    // Handle purchase completion callback
    func handlePurchaseCallback(url: URL) -> Bool {
        // Parse URL to extract subscription type and validation token
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return false
        }
        
        // Check for success parameter
        if let successParam = queryItems.first(where: { $0.name == "success" })?.value,
           successParam == "true" {
            
            // Get subscription type
            if let typeParam = queryItems.first(where: { $0.name == "type" })?.value,
               let subType = SubscriptionType(rawValue: typeParam) {
                updateSubscription(type: subType)
                return true
            }
        }
        
        return false
    }
    
    // Reset purchase state (for testing or account logout)
    func resetPurchaseState() {
        subscriptionType = .none
        isPro = false
        isTestMode = false
        saveSubscriptionState()
    }
    
    // MARK: - Private Methods
    
    // Save subscription state to Keychain
    private func saveSubscriptionState() {
        saveToKeychain(key: "subscriptionType", value: subscriptionType.rawValue)
        saveToKeychain(key: "isPro", value: isPro ? "true" : "false")
        saveToKeychain(key: "isTestMode", value: isTestMode ? "true" : "false")
    }
    
    // Load subscription state from Keychain
    private func loadSubscriptionState() {
        if let subTypeStr = readFromKeychain(key: "subscriptionType"),
           let subType = SubscriptionType(rawValue: subTypeStr) {
            subscriptionType = subType
        }
        
        if let isProStr = readFromKeychain(key: "isPro") {
            isPro = (isProStr == "true")
        }
        
        if let isTestModeStr = readFromKeychain(key: "isTestMode") {
            isTestMode = (isTestModeStr == "true")
        }
    }
    
    // MARK: - Keychain Methods
    
    private func saveToKeychain(key: String, value: String) {
        let fullKey = keyPrefix + key
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: fullKey,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }
    
    private func readFromKeychain(key: String) -> String? {
        let fullKey = keyPrefix + key
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: fullKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            return nil
        }
    }
} 