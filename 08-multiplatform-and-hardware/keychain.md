# Keychain - Secure Credential Storage

## Overview

The Keychain is a secure storage service for storing passwords, encryption keys, certificates, and sensitive data. It's encrypted by the operating system and protected by biometric/PIN.

## Main Topics

- [Basic Keychain Operations](#basic-keychain-operations)
- [SecureEnclave](#secureenclave)
- [Keychain Error Handling](#keychain-error-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

---

## Basic Keychain Operations

### Simple KeychainHelper

```swift
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    func save(password: String, for account: String) -> Bool {
        guard let data = password.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil) == noErr
    }
    
    func retrieve(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == noErr, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func delete(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        return SecItemDelete(query as CFDictionary) == noErr
    }
}
```

### Advanced Keychain Management

```swift
import Security

class AdvancedKeychainManager {
    static let shared = AdvancedKeychainManager()
    
    enum KeychainError: Error {
        case itemNotFound
        case failedToSave
        case failedToDelete
        case failedToUpdate
    }
    
    func saveAuthToken(_ token: String, username: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.failedToSave
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: "com.myapp.auth",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == noErr else {
            throw KeychainError.failedToSave
        }
    }
    
    func retrieveAuthToken(username: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: "com.myapp.auth",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == noErr, let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }
        
        return token
    }
    
    func updateAuthToken(_ newToken: String, username: String) throws {
        guard let data = newToken.data(using: .utf8) else {
            throw KeychainError.failedToUpdate
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: "com.myapp.auth"
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == noErr else {
            throw KeychainError.failedToUpdate
        }
    }
}
```

---

## SecureEnclave

### Protected by Biometric

```swift
import Security
import LocalAuthentication

class BiometricProtectedStorage {
    static let shared = BiometricProtectedStorage()
    
    func saveBiometricProtectedData(_ data: String, key: String) throws {
        guard let encodedData = data.data(using: .utf8) else {
            throw NSError(domain: "Encoding", code: -1)
        }
        
        // Create access control requiring biometric
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            &error
        ) else {
            throw error?.takeRetainedValue() ?? NSError(domain: "Security", code: -1)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encodedData,
            kSecAttrAccessControl as String: access
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == noErr else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
    }
    
    func retrieveBiometricProtectedData(key: String) throws -> String {
        let context = LAContext()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: "Authenticate to access this data"
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == noErr, let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
        
        return string
    }
}
```

---

## Keychain Error Handling

### Comprehensive Error Management

```swift
import Security

class KeychainErrorHandler {
    static func statusErrorMessage(_ status: OSStatus) -> String {
        switch status {
        case noErr:
            return "Success"
        case errSecUnimplemented:
            return "Function not implemented"
        case errSecParam:
            return "Invalid parameters"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecInteractionNotAllowed:
            return "User interaction not allowed"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecDataNotAvailable:
            return "Data not available"
        default:
            return "Unknown error: \(status)"
        }
    }
    
    static func handle(_ status: OSStatus) throws {
        guard status == noErr else {
            throw NSError(
                domain: "KeychainError",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: statusErrorMessage(status)]
            )
        }
    }
}

// Usage
do {
    try KeychainErrorHandler.handle(status)
} catch {
    print("Keychain error: \(error.localizedDescription)")
}
```

---

## 🎯 Best Practices

### 1. Use Accessibility Level
```swift
// ✅ Restrict when device is locked
kSecAttrAccessibleWhenUnlockedThisDeviceOnly

// ❌ Allow access when locked
kSecAttrAccessibleAlways  // Security risk
```

### 2. Check Biometric Availability
```swift
// ✅ Check before requiring biometric
let context = LAContext()
if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
    // Use biometric protection
}

// ❌ Assume biometric is available
// Will fail on devices without biometric
```

### 3. Handle Missing Items Gracefully
```swift
// ✅ Expect optional results
let token = try? keychainManager.retrieveAuthToken(username: user)
if token == nil {
    // Handle first-time setup
}

// ❌ Force unwrap
let token = try keychainManager.retrieveAuthToken(username: user)!
```

---

## ❌ Common Mistakes

### Mistake 1: Storing Plain Text

**WRONG:**
```swift
// ❌ Storing sensitive data in UserDefaults
UserDefaults.standard.set(password, forKey: "password")

// ❌ Storing in files without encryption
try password.write(toFile: path, atomically: true, encoding: .utf8)
```

**CORRECT:**
```swift
// ✅ Use Keychain
KeychainHelper.shared.save(password: password, for: account)
```

---

### Mistake 2: Not Deleting Old Items

**WRONG:**
```swift
// ❌ Duplicate items accumulate
func updatePassword(_ password: String, for account: String) {
    KeychainHelper.shared.save(password: password, for: account)
    // Old password still exists
}
```

**CORRECT:**
```swift
// ✅ Delete before saving
func updatePassword(_ password: String, for account: String) {
    KeychainHelper.shared.delete(for: account)
    KeychainHelper.shared.save(password: password, for: account)
}
```

---

### Mistake 3: Ignoring Accessibility

**WRONG:**
```swift
// ❌ No accessibility specified
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecValueData as String: data
]

// ❌ Leaves default accessibility (often unsafe)
SecItemAdd(query as CFDictionary, nil)
```

**CORRECT:**
```swift
// ✅ Explicitly set accessibility
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    kSecValueData as String: data
]

SecItemAdd(query as CFDictionary, nil)
```

---

## Related Topics

- [API Authentication](../03-networking/api-authentication.md)
- [Local Authentication (BiometricID)](../06-security/authentication.md)
- [UserDefaults](userdefaults.md)

---

**Keep your app's secrets safe with Keychain!**
