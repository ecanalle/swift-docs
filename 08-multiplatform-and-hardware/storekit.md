# StoreKit - In-App Purchases and Subscriptions

## Overview

StoreKit handles in-app purchases, subscriptions, and app transactions. StoreKit 2 provides a modern async/await API.

## Main Topics

- [StoreKit 2 Basics](#storekit-2-basics)
- [Product Requests](#product-requests)
- [Purchase Handling](#purchase-handling)
- [Subscription Management](#subscription-management)
- [Transaction Verification](#transaction-verification)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [StoreKit 2](https://developer.apple.com/documentation/storekit)

---

## StoreKit 2 Basics

### Products Setup

```swift
import StoreKit

class ProductManager {
    static let shared = ProductManager()
    
    // Define product IDs
    enum ProductID: String {
        case removeAds = "com.example.removeads"
        case premiumFeature = "com.example.premium"
        case monthlySubscription = "com.example.subscription.monthly"
        case yearlySubscription = "com.example.subscription.yearly"
    }
    
    @MainActor
    func fetchProducts() async throws -> [Product] {
        let productIdentifiers: Set<String> = [
            ProductID.removeAds.rawValue,
            ProductID.premiumFeature.rawValue,
            ProductID.monthlySubscription.rawValue,
            ProductID.yearlySubscription.rawValue
        ]
        
        let products = try await Product.products(for: productIdentifiers)
        return products.sorted { $0.price < $1.price }
    }
}
```

### Displaying Products

```swift
import StoreKit

@MainActor
class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let productManager = ProductManager.shared
    
    func loadProducts() async {
        isLoading = true
        
        do {
            products = try await productManager.fetchProducts()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct ProductRow: View {
    let product: Product
    var onPurchase: () async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { Task { await onPurchase() } }) {
                Text(product.displayPrice)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

---

## Product Requests

### Fetching Product Information

```swift
import StoreKit

class ProductFetcher {
    @MainActor
    static func fetchSingleProduct(id: String) async throws -> Product? {
        guard let product = try await Product.products(for: [id]).first else {
            return nil
        }
        return product
    }
    
    @MainActor
    static func fetchAllProducts(ids: [String]) async throws -> [Product] {
        return try await Product.products(for: Set(ids))
    }
    
    @MainActor
    static func getSubscriptionInfo(productID: String) async throws -> Product? {
        guard let product = try await Product.products(for: [productID]).first,
              product.type == .autoRenewable else {
            return nil
        }
        return product
    }
}

// Usage
if let premiumProduct = try await ProductFetcher.fetchSingleProduct(id: "com.example.premium") {
    print("Price: \(premiumProduct.displayPrice)")
    print("Description: \(premiumProduct.description)")
}
```

---

## Purchase Handling

### Making Purchases

```swift
import StoreKit

class PurchaseManager {
    static let shared = PurchaseManager()
    
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                print("Purchase successful: \(transaction.productID)")
                return true
                
            case .userCancelled:
                print("User cancelled purchase")
                return false
                
            case .pending:
                print("Purchase pending - requires user action")
                return false
                
            @unknown default:
                return false
            }
        } catch {
            print("Purchase error: \(error)")
            throw error
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            print("Verification failed: \(error)")
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
```

### Purchase View

```swift
import SwiftUI
import StoreKit

struct PurchaseView: View {
    let product: Product
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    var onPurchaseComplete: () -> Void
    
    private let purchaseManager = PurchaseManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text(product.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(product.description)
                .font(.body)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: { Task { await makePurchase() } }) {
                if isPurchasing {
                    ProgressView()
                } else {
                    Text("Buy for \(product.displayPrice)")
                }
            }
            .disabled(isPurchasing)
            .buttonStyle(.borderedProminent)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func makePurchase() async {
        isPurchasing = true
        
        do {
            let success = try await purchaseManager.purchase(product)
            if success {
                onPurchaseComplete()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isPurchasing = false
    }
}
```

---

## Subscription Management

### Handling Subscriptions

```swift
import StoreKit

class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionInfo?
    @Published var isMember = false
    
    init() {
        Task {
            await updateSubscriptionStatus()
            listenForTransactions()
        }
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            
            if !isPastExpirationDate(transaction) && transaction.productID.contains("subscription") {
                hasActiveSubscription = true
                
                self.subscriptionStatus = SubscriptionInfo(
                    productID: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate
                )
            }
        }
        
        self.isMember = hasActiveSubscription
    }
    
    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                let transaction = try checkVerified(result)
                await updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    private func isPastExpirationDate(_ transaction: Transaction) -> Bool {
        guard let expirationDate = transaction.expirationDate else {
            return false
        }
        return Date() > expirationDate
    }
}

struct SubscriptionInfo {
    let productID: String
    let purchaseDate: Date
    let expirationDate: Date?
}
```

---

## Transaction Verification

### Secure Transaction Handling

```swift
import StoreKit

class TransactionVerifier {
    static func verifyTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(let unverified, let error):
            print("Unverified transaction: \(error)")
            throw StoreKitError.verificationFailed
            
        case .verified(let verified):
            print("Verified transaction: \(verified.productID)")
            return verified
        }
    }
    
    static func verifyJWT(_ jwt: String) throws -> Bool {
        // Production: Verify with App Store
        // For now, basic validation
        return !jwt.isEmpty
    }
}

enum StoreKitError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed"
        case .networkError:
            return "Network error"
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Always Verify Transactions
```swift
// ✅ Verify all transactions
let transaction = try checkVerified(result)

// ❌ Trust unverified transactions
let unverified = result.unsafePayload
```

### 2. Handle All Purchase States
```swift
// ✅ Handle all cases
switch result {
case .success:
case .userCancelled:
case .pending:
}

// ❌ Ignore pending purchases
```

### 3. Request Products at App Launch
```swift
// ✅ Fetch products early
AppDelegate: loadProducts()

// ❌ Fetch only when store view shown
// Delays first purchase
```

---

## ❌ Common Mistakes

### Mistake 1: No Transaction Verification

**WRONG:**
```swift
// ❌ Trusting unverified purchases
let result = try await product.purchase()
grantPremiumAccess()  // Risky!
```

**CORRECT:**
```swift
// ✅ Always verify
let result = try await product.purchase()
let transaction = try checkVerified(result)
grantPremiumAccess()
```

---

### Mistake 2: Not Finishing Transactions

**WRONG:**
```swift
// ❌ Transaction hangs
let transaction = try checkVerified(result)
// Never call finish()
```

**CORRECT:**
```swift
// ✅ Always finish
let transaction = try checkVerified(result)
await transaction.finish()
```

---

## Related Topics

- [API Authentication](../03-networking/api-authentication.md)
- [UserDefaults - Preferences](userdefaults.md)
- [Keychain - Secure Storage](keychain.md)

---

**Monetize your app with StoreKit!**
