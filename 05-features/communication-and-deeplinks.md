# Communication and Deep Links - URL Schemes and Universal Links

## Overview

Deep linking enables direct navigation to specific app content via URLs. Universal Links (HTTPS) and URL schemes provide seamless integration with other apps, web browsers, and system features.

## Main Topics

- [URL Schemes](#url-schemes)
- [Universal Links](#universal-links)
- [Deep Link Handling](#deep-link-handling)
- [Passing Data](#passing-data-through-links)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [URL Schemes](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_to_communicate_with_url_schemes)
- [WWDC 2015: Deeplinks for iOS](https://developer.apple.com/videos/play/wwdc2015/509/)

---

## URL Schemes

### Registering URL Schemes

URL schemes are custom protocols (like `myapp://`) that iOS uses to launch your app.

**In Info.plist:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.myapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
            <string>myapp-beta</string>
        </array>
    </dict>
</array>
```

### Handling URL Scheme Calls

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Handle URLs
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // ✅ Correct: Parse and validate URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        let action = components.host ?? ""
        let queryItems = components.queryItems ?? []
        
        switch action {
        case "open-profile":
            if let userID = queryItems.first(where: { $0.name == "id" })?.value {
                navigateToProfile(userID: userID)
                return true
            }
            
        case "view-item":
            if let itemID = queryItems.first(where: { $0.name == "itemId" })?.value {
                navigateToItem(itemID: itemID)
                return true
            }
            
        default:
            return false
        }
        
        return false
    }
    
    private func navigateToProfile(userID: String) {
        // Navigate to profile screen
    }
    
    private func navigateToItem(itemID: String) {
        // Navigate to item screen
    }
}
```

### Opening Other Apps with URL Schemes

```swift
import UIKit

class AppLauncher {
    
    // Open Mail app with specific recipient
    static func sendEmail(to recipient: String) {
        let urlString = "mailto:\(recipient)?subject=Hello"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Phone app
    static func makePhoneCall(number: String) {
        let cleanedNumber = number.filter { $0.isNumber }
        let urlString = "tel:\(cleanedNumber)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Maps app
    static func openMaps(latitude: Double, longitude: Double) {
        let urlString = "maps://?saddr=&daddr=\(latitude),\(longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Open custom app
    static func openMyApp(action: String, parameters: [String: String]) {
        var urlString = "myapp://\(action)"
        
        if !parameters.isEmpty {
            urlString += "?"
            let query = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += query
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// Usage
AppLauncher.openMyApp(action: "view-item", parameters: ["itemId": "12345"])
```

---

## Universal Links

### Setting Up Universal Links

Universal Links use HTTPS and the Apple App Site Association file to provide seamless integration.

**1. Create `.well-known/apple-app-site-association` on your server:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABCDE12345.com.example.myapp",
        "paths": [
          "/user/*",
          "/item/*",
          "/NOT /admin/*"
        ]
      }
    ]
  }
}
```

**2. Enable Associated Domains in Xcode:**
- Signing & Capabilities → Associated Domains
- Add: `applinks:example.com`

**3. Verify certificate validity (HTTPS required)**

### Handling Universal Links

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // ✅ Correct: Handle Universal Links
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        
        guard let url = userActivity.webpageURL else {
            return false
        }
        
        // Parse URL and navigate
        handleUniversalLink(url)
        return true
    }
    
    private func handleUniversalLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        let pathComponents = components.path.split(separator: "/").map(String.init)
        
        if pathComponents.count >= 2 {
            let type = pathComponents[0]
            let id = pathComponents[1]
            
            switch type {
            case "user":
                navigateToProfile(userID: id)
            case "item":
                navigateToItem(itemID: id)
            default:
                break
            }
        }
    }
    
    private func navigateToProfile(userID: String) { }
    private func navigateToItem(itemID: String) { }
}
```

---

## Deep Link Handling

### Centralized Deep Link Router

```swift
import UIKit

enum DeepLinkAction {
    case profile(userID: String)
    case item(itemID: String)
    case settings
    case message(to: String, text: String)
}

class DeepLinkRouter {
    
    static func parse(url: URL) -> DeepLinkAction? {
        // ✅ Correct: Comprehensive URL parsing
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        // URL format: myapp://type/id?param=value
        let pathComponents = path.split(separator: "/").map(String.init)
        
        guard let action = pathComponents.first else { return nil }
        
        switch action {
        case "profile":
            if let userID = pathComponents.dropFirst().first {
                return .profile(userID: userID)
            }
            
        case "item":
            if let itemID = pathComponents.dropFirst().first {
                return .item(itemID: itemID)
            }
            
        case "message":
            let to = queryItems.first(where: { $0.name == "to" })?.value ?? ""
            let text = queryItems.first(where: { $0.name == "text" })?.value ?? ""
            return .message(to: to, text: text)
            
        case "settings":
            return .settings
            
        default:
            return nil
        }
    }
    
    static func navigate(to action: DeepLinkAction, from viewController: UIViewController) {
        switch action {
        case .profile(let userID):
            let profileVC = ProfileViewController(userID: userID)
            viewController.navigationController?.pushViewController(profileVC, animated: true)
            
        case .item(let itemID):
            let itemVC = ItemViewController(itemID: itemID)
            viewController.navigationController?.pushViewController(itemVC, animated: true)
            
        case .settings:
            let settingsVC = SettingsViewController()
            viewController.navigationController?.pushViewController(settingsVC, animated: true)
            
        case .message(let to, let text):
            let composeVC = ComposeViewController(recipient: to, initialText: text)
            viewController.navigationController?.pushViewController(composeVC, animated: true)
        }
    }
}
```

---

## Passing Data Through Links

### Query Parameters

```swift
// ✅ Correct: Using URLComponents for safe encoding
func createDeepLink(userID: String, referrer: String) -> URL? {
    var components = URLComponents()
    components.scheme = "myapp"
    components.host = "profile"
    components.queryItems = [
        URLQueryItem(name: "id", value: userID),
        URLQueryItem(name: "referrer", value: referrer)
    ]
    return components.url
}

// Usage
if let link = createDeepLink(userID: "12345", referrer: "search") {
    print(link.absoluteString) // myapp://profile?id=12345&referrer=search
}
```

### Encoding Special Characters

```swift
// ✅ Correct: URL encoding handles special characters
let message = "Hello, how are you? & thanks!"
let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

var components = URLComponents()
components.scheme = "myapp"
components.host = "message"
components.queryItems = [
    URLQueryItem(name: "text", value: encodedMessage)
]

// ❌ Avoid: Manual string concatenation
let wrongURL = "myapp://message?text=\(message)" // May break!
```

### JSON Payloads

```swift
// For complex data
func createDeepLinkWithJSON(data: [String: Any]) -> URL? {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        let encoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var components = URLComponents()
        components.scheme = "myapp"
        components.host = "data"
        components.queryItems = [
            URLQueryItem(name: "payload", value: encoded)
        ]
        
        return components.url
    } catch {
        return nil
    }
}
```

---

## ✅ Best Practices

### Practice 1: Validate URLs Before Processing

**DO:**
```swift
guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      let action = components.host,
      !action.isEmpty else {
    return false
}
```

### Practice 2: Use Universal Links Over URL Schemes

**DO:**
```swift
// Prefer Universal Links (HTTPS) for external URLs
// Use URL Schemes for app-to-app communication
```

### Practice 3: Handle Deep Links at App Startup

**DO:**
```swift
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Check for launch URL
    if let url = launchOptions?[.url] as? URL {
        handleDeepLink(url)
    }
    
    return true
}
```

### Practice 4: Use Strong Types

**DO:**
```swift
enum AppRoute {
    case profile(id: String)
    case item(id: String)
}

func handle(_ route: AppRoute) { }
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Fragile URL Parsing

**WRONG:**
```swift
let userID = url.absoluteString.split(separator: "/").last
// Breaks if URL format changes
```

**CORRECT:**
```swift
guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      let pathComponents = components.path.split(separator: "/"),
      let userID = pathComponents.last else {
    return false
}
```

### Mistake 2: Not Decoding Query Parameters

**WRONG:**
```swift
let value = queryItems.first?.value
// Contains URL-encoded special characters
```

**CORRECT:**
```swift
let encodedValue = queryItems.first?.value ?? ""
let decodedValue = encodedValue.removingPercentEncoding ?? encodedValue
```

### Mistake 3: Hardcoded App Links

**WRONG:**
```swift
let link = "myapp://profile?id=\(userID)"
```

**CORRECT:**
```swift
let link = createDeepLink(userID: userID)
// Centralized URL generation
```

### Mistake 4: Not Testing on Device

**WRONG:**
```swift
// Only testing in simulator
// Universal Links don't work in simulator
```

**CORRECT:**
```swift
// Test on actual device with proper certificates
// Verify SSL certificates are valid
```

---

## 🔗 Related Topics

- [App Store and Release](../04-app-lifecycle/app-store-and-release.md) - Deep link verification
- [Networking and APIs](../03-networking/api-authentication.md) - Handling API responses with deep links
- [Notifications](../04-app-lifecycle/notifications.md) - Deep links in push notifications
- [Shortcuts](./siri-and-app-intents.md) - Deep linking through Siri Shortcuts

---

**Master deep linking for seamless app navigation and cross-app integration!**
