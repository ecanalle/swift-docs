# App Extensions - Expanding Your App's Reach 🎯

## Overview
App Extensions allow your app to extend functionality beyond its boundaries—from share sheets to widgets, today views to custom intents. Learn to create extensions that enhance user experience across iOS, integrating seamlessly with system features.

## Main Topics
- [Extension Fundamentals](#extension-fundamentals) - Basics of extensions
- [Share Extension](#share-extension) - Custom sharing
- [Today Widget](#today-widget) - Lock screen widgets
- [Custom Intents](#custom-intents) - Siri and shortcuts
- [App Groups](#app-groups) - Data sharing
- [Extension Communication](#extension-communication) - Host-extension interaction
- [Best Practices](#-best-practices) - Extension strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - Extension pitfalls

## Official Documentation
- [Apple: App Extensions](https://developer.apple.com/documentation/widgetkit)
- [Apple: WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Apple: Custom Intents](https://developer.apple.com/documentation/sirikit)

---

## Extension Fundamentals

### Creating an Extension Target

```swift
// ✅ Correct: Extension project structure
// Main App Target:
//   MyApp/
//   ├── MyApp.swift
//   └── Views/
//
// Extension Target:
//   MyAppShare/
//   ├── ShareViewController.swift
//   └── ShareExtension.entitlements

// ShareExtension.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.default-data-protection</key>
    <string>NSFileProtectionComplete</string>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.example.myapp</string>
    </array>
</dict>
</plist>
```

**Key Points:**
- Extensions run as separate processes from main app
- Share App Groups to communicate with main app
- Memory limitations are stricter than main app
- Use same bundle ID prefix as main app

---

## Share Extension

### Implementing Share Extension

```swift
// ✅ Correct: Basic share extension
import UIKit
import Social

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let context = extensionContext!
        
        // Get shared items
        guard let inputItems = context.inputItems as? [NSExtensionItem] else {
            dismissWithError()
            return
        }
        
        for item in inputItems {
            // Handle different content types
            if let attachments = item.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        handleImageShare(attachment)
                    } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        handleURLShare(attachment)
                    } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        handleTextShare(attachment)
                    }
                }
            }
        }
    }
    
    private func handleImageShare(_ attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.image.identifier) { data, error in
            if let image = data as? UIImage {
                // Save to app group container
                self.saveImage(image)
                self.dismissWithSuccess()
            }
        }
    }
    
    private func handleURLShare(_ attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { data, error in
            if let url = data as? URL {
                self.saveURL(url)
                self.dismissWithSuccess()
            }
        }
    }
    
    private func handleTextShare(_ attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, error in
            if let text = data as? String {
                self.saveText(text)
                self.dismissWithSuccess()
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            groupDefaults?.set(imageData, forKey: "sharedImage")
        }
    }
    
    private func saveURL(_ url: URL) {
        let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
        groupDefaults?.set(url.absoluteString, forKey: "sharedURL")
    }
    
    private func saveText(_ text: String) {
        let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
        groupDefaults?.set(text, forKey: "sharedText")
    }
    
    private func dismissWithSuccess() {
        extensionContext?.completeRequest(returningItems: nil)
    }
    
    private func dismissWithError() {
        let error = NSError(domain: "ShareExtension", code: -1)
        extensionContext?.cancelRequest(withError: error)
    }
}

// Info.plist configuration
/*
NSExtensionAttributes:
    NSExtensionActivationRule: SUBQUERY(
        $attachment,
        $a,
        UNIFORM_TYPE_IS_UTI($a.registeredTypeIdentifier, "public.image") ||
        UNIFORM_TYPE_IS_UTI($a.registeredTypeIdentifier, "public.url")
    ).@count == 1
*/
```

---

## Today Widget

### Creating WidgetKit Widget

```swift
// ✅ Correct: Modern WidgetKit implementation
import WidgetKit
import SwiftUI

// Define widget family and data
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            content: { entry in
                QuoteWidgetView(entry: entry)
            }
        )
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Daily Quote")
        .description("Shows inspiring daily quote")
    }
}

// Data model
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
    let author: String
}

// Timeline provider
struct Provider: TimelineProvider {
    typealias Entry = QuoteEntry
    
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(
            date: Date(),
            quote: "The only way to do great work is to love what you do.",
            author: "Steve Jobs"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        var entries: [QuoteEntry] = []
        
        // Generate timeline entries
        let currentDate = Date()
        for dayOffset in 0..<7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let quote = getQuoteForDate(entryDate)
            let entry = QuoteEntry(date: entryDate, quote: quote.text, author: quote.author)
            entries.append(entry)
        }
        
        // Refresh every day
        let nextRefresh = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        
        completion(timeline)
    }
    
    private func getQuoteForDate(_ date: Date) -> (text: String, author: String) {
        // Fetch from app group storage or API
        return ("Quote", "Author")
    }
}

// Widget view
struct QuoteWidgetView: View {
    var entry: QuoteEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.quote)
                .font(.caption)
                .lineLimit(3)
            
            Text("— \(entry.author)")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
    }
}
```

### Lock Screen Widget (iOS 16+)

```swift
// ✅ Correct: iOS 16 lock screen widget
import WidgetKit
import SwiftUI

struct LockScreenQuoteWidget: Widget {
    let kind: String = "LockScreenQuote"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            content: { entry in
                LockScreenQuoteView(entry: entry)
            }
        )
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
        .configurationDisplayName("Lock Screen Quote")
    }
}

struct LockScreenQuoteView: View {
    var entry: QuoteEntry
    
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading) {
                Text(entry.quote)
                    .font(.caption2)
                    .lineLimit(2)
            }
            .widgetLabel {
                Image(systemName: "quote.bubble")
            }
        }
    }
}
```

---

## Custom Intents

### Siri Intent Handler

```swift
// ✅ Correct: Custom Siri intent
import Intents

class SaveQuoteIntentHandler: NSObject, SaveQuoteIntentHandling {
    func handle(intent: SaveQuoteIntent, completion: @escaping (SaveQuoteIntentResponse) -> Void) {
        guard let quote = intent.quote else {
            completion(SaveQuoteIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // Save to app group storage
        let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
        var savedQuotes = groupDefaults?.stringArray(forKey: "savedQuotes") ?? []
        savedQuotes.append(quote)
        groupDefaults?.set(savedQuotes, forKey: "savedQuotes")
        
        let response = SaveQuoteIntentResponse(code: .success, userActivity: nil)
        response.quote = quote
        completion(response)
    }
    
    // Provide dynamic options for Siri suggestions
    func resolveQuote(for intent: SaveQuoteIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let quote = intent.quote {
            completion(INStringResolutionResult.success(with: quote))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
}

// Intent definition file (SaveQuote.intentdefinition)
/*
- Intent: SaveQuote
  - Input: Quote (String)
  - Output: Quote (String)
  - Shortcut: "Save this quote"
*/
```

---

## App Groups

### Sharing Data via App Groups

```swift
// ✅ Correct: Data sharing between app and extensions
class AppGroupManager {
    static let groupIdentifier = "group.com.example.myapp"
    
    static func saveToAppGroup(key: String, value: Any) {
        let groupDefaults = UserDefaults(suiteName: groupIdentifier)
        groupDefaults?.set(value, forKey: key)
        groupDefaults?.synchronize()
    }
    
    static func readFromAppGroup(key: String) -> Any? {
        let groupDefaults = UserDefaults(suiteName: groupIdentifier)
        return groupDefaults?.object(forKey: key)
    }
    
    static func getAppGroupURL() -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }
}

// Usage in main app
let quotes: [String] = ["Quote 1", "Quote 2"]
AppGroupManager.saveToAppGroup(key: "quotes", value: quotes)

// Usage in extension
if let quotes = AppGroupManager.readFromAppGroup(key: "quotes") as? [String] {
    print("Quotes: \(quotes)")
}
```

---

## Extension Communication

### Communicating with Host App

```swift
// ✅ Correct: Extension to main app communication
import UserNotifications

class ExtensionCommunicator {
    static func notifyMainApp(with data: [String: Any]) {
        // Option 1: Shared UserDefaults
        let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
        groupDefaults?.set(data, forKey: "extensionData")
        
        // Option 2: Shared file container
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.example.myapp"
        ) {
            let fileURL = groupURL.appendingPathComponent("extensionData.json")
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                try jsonData.write(to: fileURL)
            } catch {
                print("Error writing data: \(error)")
            }
        }
    }
    
    static func openMainApp() {
        // Extensions can't directly open main app in iOS 13+
        // Instead, use a custom URL scheme
        guard let appURL = URL(string: "myapp://fromExtension") else { return }
        
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                // Can't open URLs from extension directly
                // Use shared data instead
            }
        }
    }
}
```

---

## ✅ Best Practices

### Practice 1: Minimize Extension Size
**DO:**
```swift
// ✅ Extensions have strict memory limits
// Keep code lean and efficient
// Remove unused dependencies

// ✅ Share frameworks with main app to reduce size
```

### Practice 2: Use App Groups for Communication
**DO:**
```swift
// ✅ UserDefaults with suiteName
UserDefaults(suiteName: "group.com.example.myapp")

// ✅ File container
FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.example.myapp"
)
```

### Practice 3: Handle Timeouts Gracefully
**DO:**
```swift
// ✅ Extensions have 10-second timeout
// Show fallback UI if needed
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    // Fetch data with timeout handling
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
        completion(Timeline(entries: [], policy: .never))
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Trying to Open Main App from Extension
**WRONG:**
```swift
// ❌ Can't do this from extension
UIApplication.shared.open(url)
```

**CORRECT:**
```swift
// ✅ Use shared data and let main app handle it
let groupDefaults = UserDefaults(suiteName: "group.com.example.myapp")
groupDefaults?.set(true, forKey: "shouldShowData")
```

### Mistake 2: Storing Large Data in Extension Memory
**WRONG:**
```swift
// ❌ Too much data for extension
let largeCache = NSMutableDictionary()
for i in 0..<100000 {
    largeCache[i] = generateHeavyObject()
}
```

**CORRECT:**
```swift
// ✅ Use disk storage or app group
let fileURL = groupContainerURL.appendingPathComponent("cache.json")
// Save to disk, load on demand
```

### Mistake 3: Forgetting to Set App Group Capability
**WRONG:**
```
// ❌ App groups not enabled in capabilities
// Extension can't access shared data
```

**CORRECT:**
```
✅ Enable "App Groups" capability in main target AND extension target
✅ Use same app group identifier in both
```

---

## 🔗 Related Topics
- [App Lifecycle](../04-app-lifecycle/app-store-and-release.md) - Extension deployment
- [User Notifications](../04-app-lifecycle/notifications.md) - Notification extensions
- [Data Persistence](../06-data/persistence-and-storage.md) - Storing extension data
- [Siri Integration](../05-features/siri-and-app-intents.md) - Custom intents
