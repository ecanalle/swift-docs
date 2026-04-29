# Logging & Monitoring - Production Diagnostics 🎯

## Overview
Effective logging and monitoring are critical for understanding app behavior in production. From os.log for efficient on-device logging to analytics frameworks and crash reporting, learn how to instrument your app for real-world performance insights.

## Main Topics
- [os.log Framework](#oslog-framework) - Efficient system logging
- [Structured Logging](#structured-logging) - Organizing log data
- [Crash Reporting](#crash-reporting) - Capturing and reporting crashes
- [Analytics Integration](#analytics-integration) - Tracking user behavior
- [Performance Monitoring](#performance-monitoring) - Measuring app health
- [Remote Logging](#remote-logging) - Sending logs to servers
- [Best Practices](#-best-practices) - Logging strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - Avoiding pitfalls

## Official Documentation
- [Apple: os.log](https://developer.apple.com/documentation/os/logging)
- [Apple: os_log API Reference](https://developer.apple.com/documentation/os/os_log)
- [WWDC 2018: Logging Best Practices](https://developer.apple.com/videos/play/wwdc2018/405)

---

## os.log Framework

### Basic Logging with os.log

The `os.log` framework is Apple's recommended logging system. It's efficient, secure, and integrates with Xcode's console.

```swift
// ✅ Correct: Using os.log with proper log levels
import os.log

let logger = os.log(subsystem: "com.example.myapp", category: "networking")

// Default log level - visible in console
os.log("Application started", log: logger)

// Debug level - only visible when debugging
os.log("Parsing response: %@", log: logger, type: .debug, responseString)

// Info level - informational messages
os.log("Connected to server", log: logger, type: .info)

// Error level - error conditions
os.log("Network error: %@", log: logger, type: .error, error.localizedDescription)

// Fault level - severe errors
os.log("Database corrupted!", log: logger, type: .fault)
```

**Key Points:**
- Use format strings with `%@` for objects and `%d` for integers
- Log levels control visibility and performance impact
- Sensitive data is automatically redacted in production logs
- Use subsystem and category for organization

### Creating Custom Loggers

```swift
// ✅ Correct: Setting up custom loggers by category
import os.log

class LoggerManager {
    static let networking = os.log(subsystem: "com.example.myapp", category: "networking")
    static let database = os.log(subsystem: "com.example.myapp", category: "database")
    static let ui = os.log(subsystem: "com.example.myapp", category: "ui")
    static let security = os.log(subsystem: "com.example.myapp", category: "security")
}

// Usage throughout app
func fetchUserData() {
    os.log("Fetching user data", log: LoggerManager.networking, type: .info)
    
    do {
        let data = try fetchFromServer()
        os.log("Fetch succeeded", log: LoggerManager.networking, type: .debug)
    } catch {
        os.log("Fetch failed: %@", log: LoggerManager.networking, type: .error, error.localizedDescription)
    }
}
```

---

## Structured Logging

### Using Log Messages with Formatting

```swift
// ✅ Correct: Structured logging with proper formatting
import os.log

class NetworkRequest {
    func logRequest(url: String, method: String, headers: [String: String]) {
        let logger = os.log(subsystem: "com.example.myapp", category: "networking")
        
        os.log("Starting request", log: logger, type: .debug)
        os.log("  URL: %@", log: logger, type: .debug, url)
        os.log("  Method: %@", log: logger, type: .debug, method)
        os.log("  Headers: %d", log: logger, type: .debug, headers.count)
    }
    
    func logResponse(statusCode: Int, duration: TimeInterval) {
        let logger = os.log(subsystem: "com.example.myapp", category: "networking")
        
        if statusCode >= 200 && statusCode < 300 {
            os.log("Success: %d (%.2fms)", log: logger, type: .info, statusCode, duration * 1000)
        } else if statusCode >= 400 && statusCode < 500 {
            os.log("Client error: %d (%.2fms)", log: logger, type: .error, statusCode, duration * 1000)
        } else if statusCode >= 500 {
            os.log("Server error: %d (%.2fms)", log: logger, type: .fault, statusCode, duration * 1000)
        }
    }
}

// Usage
let request = NetworkRequest()
request.logRequest(url: "api.example.com/users", method: "GET", headers: ["Authorization": "Bearer token"])
request.logResponse(statusCode: 200, duration: 0.234)
```

### Performance Tracing

```swift
// ✅ Correct: Logging performance metrics
import os.log

class PerformanceMonitor {
    let logger = os.log(subsystem: "com.example.myapp", category: "performance")
    
    func measureOperation(_ name: String, operation: () throws -> Void) throws {
        let startTime = Date()
        
        do {
            try operation()
            let duration = Date().timeIntervalSince(startTime)
            os.log("✅ %@ completed in %.3fms", log: logger, type: .info, name, duration * 1000)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            os.log("❌ %@ failed after %.3fms: %@", log: logger, type: .error, name, duration * 1000, error.localizedDescription)
            throw error
        }
    }
}

// Usage
let monitor = PerformanceMonitor()
try monitor.measureOperation("Database query") {
    try database.performExpensiveQuery()
}
```

---

## Crash Reporting

### Implementing Crash Handlers

```swift
// ✅ Correct: Capturing uncaught exceptions
import os.log

class CrashReporter {
    static let logger = os.log(subsystem: "com.example.myapp", category: "crash")
    
    static func setup() {
        // Capture uncaught exceptions
        NSSetUncaughtExceptionHandler { exception in
            os.log("Uncaught exception: %@", log: CrashReporter.logger, type: .fault, exception.reason ?? "Unknown")
            
            for symbol in exception.callStackSymbols {
                os.log("  %@", log: CrashReporter.logger, type: .fault, symbol)
            }
            
            // Send to remote server
            CrashReporter.sendCrashReport(exception: exception)
        }
        
        // Handle signals for other crash types
        signal(SIGABRT) { _ in
            os.log("SIGABRT received", log: CrashReporter.logger, type: .fault)
        }
    }
    
    static func sendCrashReport(exception: NSException) {
        // Send to crash reporting service
        DispatchQueue.global().async {
            // Post to server...
        }
    }
}

// Call in AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    CrashReporter.setup()
    return true
}
```

### Manual Error Tracking

```swift
// ✅ Correct: Explicitly logging errors and tracking them
import os.log

class ErrorTracker {
    static let logger = os.log(subsystem: "com.example.myapp", category: "errors")
    
    static func track(_ error: Error, context: String) {
        let nsError = error as NSError
        
        os.log("Error (%@): Code %d - %@", log: logger, type: .error, context, nsError.code, nsError.localizedDescription)
        
        if let underlyingError = nsError.underlyingError {
            os.log("  Underlying error: %@", log: logger, type: .error, underlyingError.localizedDescription)
        }
        
        if !nsError.localizedFailureReason.isEmpty {
            os.log("  Reason: %@", log: logger, type: .error, nsError.localizedFailureReason)
        }
        
        // Send to analytics
        sendToAnalytics(error: error, context: context)
    }
    
    static func sendToAnalytics(error: Error, context: String) {
        // Implementation...
    }
}

// Usage
do {
    try riskyOperation()
} catch {
    ErrorTracker.track(error, context: "riskyOperation")
}
```

---

## Analytics Integration

### Tracking User Events

```swift
// ✅ Correct: Structured event tracking
import os.log

class AnalyticsTracker {
    static let logger = os.log(subsystem: "com.example.myapp", category: "analytics")
    
    static func trackEvent(_ name: String, properties: [String: Any]?) {
        os.log("Event: %@", log: logger, type: .info, name)
        
        if let properties = properties {
            for (key, value) in properties {
                os.log("  %@: %@", log: logger, type: .info, key, String(describing: value))
            }
        }
        
        // Send to analytics service
        sendToAnalytics(name: name, properties: properties)
    }
    
    static func trackScreenView(_ screenName: String) {
        os.log("Screen: %@", log: logger, type: .debug, screenName)
        sendToAnalytics(name: "screen_view", properties: ["screen_name": screenName])
    }
    
    static func trackPurchase(amount: Double, currency: String, product: String) {
        os.log("Purchase: %@ %@ (%.2f)", log: logger, type: .info, currency, product, amount)
        
        let properties: [String: Any] = [
            "amount": amount,
            "currency": currency,
            "product": product,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendToAnalytics(name: "purchase", properties: properties)
    }
    
    private static func sendToAnalytics(name: String, properties: [String: Any]?) {
        // Send to analytics backend (Firebase, Mixpanel, etc.)
    }
}

// Usage throughout app
func recordPurchase() {
    AnalyticsTracker.trackEvent("subscription_purchased", properties: [
        "plan": "premium",
        "duration_months": 12,
        "price": 99.99
    ])
}
```

---

## Performance Monitoring

### Memory and CPU Tracking

```swift
// ✅ Correct: Monitoring memory and performance
import os.log
import Foundation

class PerformanceMonitor {
    static let logger = os.log(subsystem: "com.example.myapp", category: "performance")
    
    static func getMemoryUsage() -> (used: UInt64, available: UInt64) {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size/4)
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self(),
                         task_flavor_t(TASK_VM_INFO),
                         $0,
                         &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return (0, 0) }
        
        let usedMemory = UInt64(info.phys_footprint)
        let totalMemory = UInt64(ProcessInfo.processInfo.physicalMemory)
        
        return (usedMemory, totalMemory)
    }
    
    static func logMemoryUsage() {
        let (used, total) = getMemoryUsage()
        let percentage = Double(used) / Double(total) * 100
        
        os.log("Memory: %.1f MB / %.0f MB (%.1f%%)", 
               log: logger, 
               type: .debug, 
               Double(used) / 1024 / 1024,
               Double(total) / 1024 / 1024,
               percentage)
    }
}

// Monitor periodically
Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    PerformanceMonitor.logMemoryUsage()
}
```

---

## Remote Logging

### Sending Logs to Server

```swift
// ✅ Correct: Remote logging implementation
import os.log

class RemoteLogger {
    static let logger = os.log(subsystem: "com.example.myapp", category: "remote")
    private static var logBuffer: [LogEntry] = []
    
    struct LogEntry: Codable {
        let timestamp: Date
        let level: String
        let message: String
        let category: String
        let deviceId: String
    }
    
    static func setup() {
        // Periodically flush logs to server
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            RemoteLogger.flushLogs()
        }
    }
    
    static func logRemotely(_ message: String, level: String = "info", category: String = "general") {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            category: category,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        )
        
        logBuffer.append(entry)
        
        if logBuffer.count > 100 {
            flushLogs()
        }
    }
    
    static func flushLogs() {
        guard !logBuffer.isEmpty else { return }
        
        let entriesToSend = logBuffer
        logBuffer.removeAll()
        
        DispatchQueue.global().async {
            sendToServer(entriesToSend)
        }
    }
    
    private static func sendToServer(_ entries: [LogEntry]) {
        var request = URLRequest(url: URL(string: "https://api.example.com/logs")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(entries)
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    os.log("Logs sent successfully", log: logger, type: .debug)
                } else if let error = error {
                    os.log("Failed to send logs: %@", log: logger, type: .error, error.localizedDescription)
                }
            }.resume()
        } catch {
            os.log("Failed to encode logs: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
}

// Setup in AppDelegate
RemoteLogger.setup()
RemoteLogger.logRemotely("App started", level: "info")
```

---

## ✅ Best Practices

### Practice 1: Use Appropriate Log Levels
**DO:**
```swift
let logger = os.log(subsystem: "com.example.app", category: "network")

os.log("Request started", log: logger, type: .debug)      // Dev info
os.log("Connected", log: logger, type: .info)              // General info
os.log("Rate limited", log: logger, type: .error)          // Error condition
os.log("Server down!", log: logger, type: .fault)          // Critical failure
```

### Practice 2: Avoid Logging Sensitive Data
**DO:**
```swift
// ✅ Correct - data is automatically redacted in production
os.log("User logged in: %@", log: logger, type: .info, userEmail)

// Or explicitly redact
os.log("Token received", log: logger, type: .debug)  // Don't log token value
```

### Practice 3: Batch Remote Logs for Efficiency
**DO:**
```swift
class LogBatcher {
    var buffer: [LogEntry] = []
    
    func addLog(_ entry: LogEntry) {
        buffer.append(entry)
        if buffer.count >= 50 {
            flush()
        }
    }
    
    func flush() {
        // Send accumulated logs
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Logging Sensitive Information
**WRONG:**
```swift
// ❌ Exposes user data
os.log("User password: %@", log: logger, type: .debug, userPassword)
os.log("API key: %@", log: logger, type: .info, apiKey)
os.log("Token: %@", log: logger, type: .debug, bearerToken)
```

**CORRECT:**
```swift
// ✅ Never log sensitive data
os.log("User authenticated successfully", log: logger, type: .info)
os.log("API connection established", log: logger, type: .debug)
os.log("Authorization complete", log: logger, type: .debug)
```

### Mistake 2: Over-logging in Production
**WRONG:**
```swift
// ❌ Too verbose, impacts performance
for item in largeArray {
    os.log("Processing item: %@", log: logger, type: .debug, item)
}
```

**CORRECT:**
```swift
// ✅ Log summary instead
os.log("Processing %d items", log: logger, type: .debug, largeArray.count)
```

### Mistake 3: Not Removing Console Logging Before Production
**WRONG:**
```swift
// ❌ Mix of print and os.log
print("Debug: \(value)")  // Goes to console only
os.log("Error: %@", log: logger, type: .error, error)
```

**CORRECT:**
```swift
// ✅ Use only os.log consistently
os.log("Debug: %@", log: logger, type: .debug, value)
os.log("Error: %@", log: logger, type: .error, error)
```

### Mistake 4: Synchronous Remote Logging on Main Thread
**WRONG:**
```swift
// ❌ Blocks UI
os.log("Event", log: logger, type: .info)
sendLogsToServer()  // Synchronous, blocks main thread
```

**CORRECT:**
```swift
// ✅ Async background processing
os.log("Event", log: logger, type: .info)
DispatchQueue.global().async {
    self.sendLogsToServer()
}
```

---

## 🔗 Related Topics
- [Performance Optimization](performance-optimization.md) - Measuring performance
- [Error Handling](../02-architecture/error-handling.md) - Managing errors
- [Debugging](xcode-and-ide.md) - Using Xcode debugger
- [App Lifecycle](../04-app-lifecycle/app-store-and-release.md) - Production deployment
- [Concurrency](async-concurrency.md) - Background operations
