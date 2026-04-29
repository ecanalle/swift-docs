# UserDefaults - Lightweight Persistence

## Overview

UserDefaults provides simple key-value storage for user preferences and lightweight data. It's not suitable for large datasets - use Core Data or SwiftData instead.

## Main Topics

- [Basic Operations](#basic-operations)
- [Storing Complex Types](#storing-complex-types)
- [Observing Changes](#observing-changes)
- [Security Considerations](#security-considerations)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

---

## Basic Operations

### Simple Storage

```swift
import Foundation

class PreferencesManager {
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - String
    func saveUsername(_ username: String) {
        defaults.set(username, forKey: "username")
    }
    
    func getUsername() -> String? {
        return defaults.string(forKey: "username")
    }
    
    // MARK: - Int
    func saveThemeMode(_ mode: Int) {
        defaults.set(mode, forKey: "themeMode")
    }
    
    func getThemeMode() -> Int {
        return defaults.integer(forKey: "themeMode")
    }
    
    // MARK: - Bool
    func setNotificationsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: "notificationsEnabled")
    }
    
    func isNotificationsEnabled() -> Bool {
        return defaults.bool(forKey: "notificationsEnabled")
    }
    
    // MARK: - Double
    func saveFontSize(_ size: Double) {
        defaults.set(size, forKey: "fontSize")
    }
    
    func getFontSize() -> Double {
        return defaults.double(forKey: "fontSize")
    }
    
    // MARK: - Remove
    func removeUsername() {
        defaults.removeObject(forKey: "username")
    }
    
    func clearAllPreferences() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleIdentifier)
        }
    }
}
```

### Type-Safe UserDefaults

```swift
import Foundation

class TypeSafeDefaults {
    static let shared = TypeSafeDefaults()
    
    private let defaults = UserDefaults.standard
    
    enum Keys: String {
        case userId
        case userEmail
        case lastLoginDate
        case appVersion
        case isDarkMode
    }
    
    // MARK: - Getters
    var userId: Int {
        get { defaults.integer(forKey: Keys.userId.rawValue) }
        set { defaults.set(newValue, forKey: Keys.userId.rawValue) }
    }
    
    var userEmail: String? {
        get { defaults.string(forKey: Keys.userEmail.rawValue) }
        set { defaults.set(newValue, forKey: Keys.userEmail.rawValue) }
    }
    
    var lastLoginDate: Date? {
        get { defaults.object(forKey: Keys.lastLoginDate.rawValue) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastLoginDate.rawValue) }
    }
    
    var appVersion: String {
        get { defaults.string(forKey: Keys.appVersion.rawValue) ?? "1.0" }
        set { defaults.set(newValue, forKey: Keys.appVersion.rawValue) }
    }
    
    var isDarkMode: Bool {
        get { defaults.bool(forKey: Keys.isDarkMode.rawValue) }
        set { defaults.set(newValue, forKey: Keys.isDarkMode.rawValue) }
    }
    
    // MARK: - Reset
    func reset() {
        defaults.removeObject(forKey: Keys.userId.rawValue)
        defaults.removeObject(forKey: Keys.userEmail.rawValue)
        defaults.removeObject(forKey: Keys.lastLoginDate.rawValue)
        defaults.removeObject(forKey: Keys.isDarkMode.rawValue)
    }
}

// Usage
TypeSafeDefaults.shared.userEmail = "user@example.com"
TypeSafeDefaults.shared.isDarkMode = true
```

---

## Storing Complex Types

### Codable Objects

```swift
import Foundation

struct UserProfile: Codable {
    let name: String
    let email: String
    let age: Int
    let joinDate: Date
}

class ProfileManager {
    static let shared = ProfileManager()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func saveProfile(_ profile: UserProfile) throws {
        let encoded = try encoder.encode(profile)
        defaults.set(encoded, forKey: "userProfile")
    }
    
    func getProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: "userProfile") else {
            return nil
        }
        
        return try? decoder.decode(UserProfile.self, from: data)
    }
    
    func deleteProfile() {
        defaults.removeObject(forKey: "userProfile")
    }
}

// Usage
let profile = UserProfile(
    name: "John Doe",
    email: "john@example.com",
    age: 30,
    joinDate: Date()
)

try ProfileManager.shared.saveProfile(profile)
if let saved = ProfileManager.shared.getProfile() {
    print("Saved: \(saved.name)")
}
```

### Array Storage

```swift
import Foundation

class ArrayManager {
    static let shared = ArrayManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - String Array
    func saveBookmarks(_ bookmarks: [String]) {
        defaults.set(bookmarks, forKey: "bookmarks")
    }
    
    func getBookmarks() -> [String] {
        return defaults.stringArray(forKey: "bookmarks") ?? []
    }
    
    // MARK: - Complex Array
    struct Item: Codable {
        let id: Int
        let title: String
    }
    
    func saveItems(_ items: [Item]) throws {
        let encoded = try JSONEncoder().encode(items)
        defaults.set(encoded, forKey: "items")
    }
    
    func getItems() -> [Item]? {
        guard let data = defaults.data(forKey: "items") else {
            return nil
        }
        return try? JSONDecoder().decode([Item].self, from: data)
    }
}
```

---

## Observing Changes

### Key-Value Observation

```swift
import Foundation

class SettingsObserver: NSObject {
    static let shared = SettingsObserver()
    
    private let defaults = UserDefaults.standard
    var onThemeChanged: ((String) -> Void)?
    var onFontSizeChanged: ((Double) -> Void)?
    
    override init() {
        super.init()
        setupObservers()
    }
    
    private func setupObservers() {
        defaults.addObserver(
            self,
            forKeyPath: "theme",
            options: [.new],
            context: nil
        )
        
        defaults.addObserver(
            self,
            forKeyPath: "fontSize",
            options: [.new],
            context: nil
        )
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "theme" {
            if let theme = change?[.newKey] as? String {
                onThemeChanged?(theme)
            }
        } else if keyPath == "fontSize" {
            if let size = change?[.newKey] as? Double {
                onFontSizeChanged?(size)
            }
        }
    }
    
    deinit {
        defaults.removeObserver(self, forKeyPath: "theme")
        defaults.removeObserver(self, forKeyPath: "fontSize")
    }
}
```

### Reactive Observation with Combine

```swift
import Combine
import Foundation

class ReactiveSettings {
    static let shared = ReactiveSettings()
    
    private let defaults = UserDefaults.standard
    
    @Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "isDarkMode") {
        didSet {
            defaults.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var fontSize: Double = UserDefaults.standard.double(forKey: "fontSize") {
        didSet {
            defaults.set(fontSize, forKey: "fontSize")
        }
    }
}

// Usage in SwiftUI
struct SettingsView: View {
    @StateObject private var settings = ReactiveSettings.shared
    
    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $settings.isDarkMode)
            
            Slider(value: $settings.fontSize, in: 10...24, step: 1)
        }
    }
}
```

---

## Security Considerations

### Sensitive Data Warning

```swift
import Foundation

class SecurePreferences {
    static let shared = SecurePreferences()
    
    // ❌ DON'T store in UserDefaults
    func wrongWayToStorePassword(_ password: String) {
        UserDefaults.standard.set(password, forKey: "password")
        // This is insecure!
    }
    
    // ✅ Use Keychain instead
    func savePasswordSecurely(_ password: String) {
        // Use Keychain framework
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "user_account",
            kSecValueData as String: password.data(using: .utf8) ?? Data()
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
```

---

## 🎯 Best Practices

### 1. Use Type-Safe Keys
```swift
// ✅ Centralized key management
enum UserDefaultsKeys {
    static let username = "username"
    static let theme = "theme"
}

defaults.set(value, forKey: UserDefaultsKeys.username)

// ❌ Magic strings everywhere
defaults.set(value, forKey: "username")  // Easy to typo
```

### 2. Provide Default Values
```swift
// ✅ Always have fallback
let fontSize = defaults.double(forKey: "fontSize")
let actualSize = fontSize > 0 ? fontSize : 14.0

// ❌ Assume value exists
let size = defaults.double(forKey: "fontSize")  // Could be 0
```

### 3. Separate Concerns
```swift
// ✅ Dedicated manager
class AppSettings {
    func getTheme() -> String { }
    func setTheme(_ theme: String) { }
}

// ❌ Access defaults everywhere
if UserDefaults.standard.bool(forKey: "isDarkMode") { }
```

---

## ❌ Common Mistakes

### Mistake 1: Storing Sensitive Data

**WRONG:**
```swift
// ❌ Passwords in UserDefaults
UserDefaults.standard.set(password, forKey: "password")
UserDefaults.standard.set(apiToken, forKey: "token")
```

**CORRECT:**
```swift
// ✅ Use Keychain
KeychainHelper.save(password: password, for: account)
```

---

### Mistake 2: No Type Checking

**WRONG:**
```swift
// ❌ Assuming type
let age = defaults.object(forKey: "age") as! Int
// Crashes if stored as String
```

**CORRECT:**
```swift
// ✅ Safe type casting
let age = defaults.integer(forKey: "age")
if age > 0 {
    // Valid age
}
```

---

### Mistake 3: Storing Large Data

**WRONG:**
```swift
// ❌ UserDefaults for large arrays
let largeDataArray = Array(0...100000)
try defaults.encode(largeDataArray)  // Slow, unnecessary
```

**CORRECT:**
```swift
// ✅ Use Core Data or SwiftData
// For large datasets, use proper database
```

---

## Related Topics

- [Keychain - Secure Storage](keychain.md)
- [SwiftData - Modern Persistence](swiftdata.md)
- [Core Data](../06-data/core-data.md)

---

**Use UserDefaults for preferences, not secrets!**
