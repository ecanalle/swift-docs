# App Extensions - Sharing and Widgets

## Overview

App Extensions allow your app to share functionality with the system and other apps. Common types include widgets, share extensions, and notification content extensions.

## Main Topics

- [App Groups](#app-groups)
- [Share Extensions](#share-extensions)
- [Widget Extension](#widget-extension)
- [Background Tasks](#background-tasks)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [App Extensions](https://developer.apple.com/documentation/widgetkit)

---

## App Groups

### Shared Data Storage

```swift
import Foundation

class AppGroupManager {
    static let groupIdentifier = "group.com.example.myapp"
    
    static let shared = AppGroupManager()
    
    var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: groupIdentifier)
    }
    
    func saveSharedData(_ data: String, forKey key: String) {
        sharedDefaults?.set(data, forKey: key)
    }
    
    func retrieveSharedData(forKey key: String) -> String? {
        return sharedDefaults?.string(forKey: key)
    }
    
    func saveSharedArray(_ array: [String], forKey key: String) {
        sharedDefaults?.set(array, forKey: key)
    }
    
    func retrieveSharedArray(forKey key: String) -> [String]? {
        return sharedDefaults?.stringArray(forKey: key)
    }
    
    func clearSharedData() {
        guard let defaults = sharedDefaults else { return }
        
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
    }
}

// Usage in Main App
let appGroupManager = AppGroupManager.shared
appGroupManager.saveSharedData("Important Data", forKey: "sharedKey")

// Usage in Extension
if let sharedData = AppGroupManager.shared.retrieveSharedData(forKey: "sharedKey") {
    print("Shared data: \(sharedData)")
}
```

---

## Share Extensions

### Creating Share Extension

```swift
import UIKit
import Social

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        processSharedItems()
    }
    
    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier("public.url") {
                    attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { url, _ in
                        if let shareURL = url as? NSURL {
                            self.handleSharedURL(shareURL)
                        }
                    }
                }
                
                if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                    attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { text, _ in
                        if let shareText = text as? String {
                            self.handleSharedText(shareText)
                        }
                    }
                }
                
                if attachment.hasItemConformingToTypeIdentifier("public.image") {
                    attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { url, _ in
                        if let url = url as? NSURL {
                            self.handleSharedImage(url)
                        }
                    }
                }
            }
        }
    }
    
    private func handleSharedURL(_ url: NSURL) {
        AppGroupManager.shared.saveSharedData(url.absoluteString ?? "", forKey: "sharedURL")
        completeShare()
    }
    
    private func handleSharedText(_ text: String) {
        AppGroupManager.shared.saveSharedData(text, forKey: "sharedText")
        completeShare()
    }
    
    private func handleSharedImage(_ url: NSURL) {
        AppGroupManager.shared.saveSharedData(url.path ?? "", forKey: "sharedImagePath")
        completeShare()
    }
    
    private func completeShare() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
```

---

## Widget Extension

### Simple Widget

```swift
import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: String
}

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: "Loading...")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: "Widget Data")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        for i in 0..<10 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: i * 15, to: Date())!
            let entry = SimpleEntry(date: entryDate, data: "Data \(i)")
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: SimpleEntry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            Text("Unknown widget")
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Widget")
                .font(.headline)
            Text(entry.data)
                .font(.body)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Medium Widget")
                    .font(.headline)
                Text(entry.data)
                    .font(.body)
            }
            Spacer()
            Image(systemName: "star")
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack {
            Text("Large Widget")
                .font(.title2)
            Text(entry.data)
                .font(.body)
            Spacer()
        }
        .padding()
    }
}

@main
struct SimpleWidget: Widget {
    let kind: String = "SimpleWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SimpleProvider(),
            content: { entry in
                SimpleWidgetView(entry: entry)
            }
        )
        .configurationDisplayName("Simple Widget")
        .description("A simple widget example")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    SimpleWidget()
} timeline: {
    SimpleEntry(date: .now, data: "Test Data")
}
```

---

## Background Tasks

### Scheduling Background Tasks

```swift
import BackgroundTasks

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    let taskIdentifier = "com.example.myapp.backgroundtask"
    
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled")
        } catch {
            print("Failed to schedule: \(error)")
        }
    }
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        // Perform background work
        print("Background task running")
        
        // Reschedule for next time
        scheduleBackgroundTask()
        
        // Mark as complete
        task.setTaskCompleted(success: true)
    }
}
```

---

## 🎯 Best Practices

### 1. Use App Groups for Data Sharing
```swift
// ✅ Share data between app and extensions
AppGroupManager.shared.saveSharedData(data, forKey: "key")

// ❌ Try to share via main app bundle
// Won't work for extensions
```

### 2. Set Widget Update Frequency
```swift
// ✅ Realistic update schedule
.supportedFamilies([.systemSmall, .systemMedium])

// ❌ Update too frequently
// Drains battery
```

### 3. Handle Permission Sharing
```swift
// ✅ Share permissions via app groups
let permissions = getBundlePermissions()
AppGroupManager.shared.saveSharedData(permissions, forKey: "permissions")

// ❌ Assume extension has permissions
// Extension runs in isolated sandbox
```

---

## ❌ Common Mistakes

### Mistake 1: Not Using App Groups

**WRONG:**
```swift
// ❌ Extension can't access main app data
UserDefaults.standard.string(forKey: "key")
```

**CORRECT:**
```swift
// ✅ Use shared app groups
AppGroupManager.shared.retrieveSharedData(forKey: "key")
```

---

### Mistake 2: Heavy Processing in Widgets

**WRONG:**
```swift
// ❌ Complex computation in widget
var body: some View {
    let result = (0...10000).reduce(0) { $0 + $1 }
    Text("\(result)")
}
```

**CORRECT:**
```swift
// ✅ Lightweight widget
var body: some View {
    Text(entry.data)
}
```

---

## Related Topics

- [App Lifecycle](../04-app-lifecycle/app-lifecycle.md)
- [Notifications](../04-app-lifecycle/notifications.md)
- [UserDefaults - Shared Storage](userdefaults.md)

---

**Extend your app's reach with extensions!**
