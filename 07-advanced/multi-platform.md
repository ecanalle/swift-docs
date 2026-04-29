# Multi-Platform Development - iOS, macOS, watchOS & tvOS 🎯

## Overview
Swift enables building apps across Apple's entire ecosystem. Learn to share code, handle platform-specific features gracefully, and optimize for different form factors from iPhone to Apple Watch and Mac. Build truly universal Swift applications.

## Main Topics
- [Shared Code Architecture](#shared-code-architecture) - Cross-platform strategies
- [Platform Detection](#platform-detection) - Conditional compilation
- [Adaptive UI](#adaptive-ui) - Responsive interfaces
- [Platform-Specific APIs](#platform-specific-apis) - Feature gates
- [watchOS Development](#watchos-development) - Apple Watch basics
- [tvOS Development](#tvos-development) - Apple TV apps
- [Best Practices](#-best-practices) - Multi-platform strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - Platform pitfalls

## Official Documentation
- [Apple: Developing for Multiple Platforms](https://developer.apple.com/documentation/xcode/developing-for-multiple-platforms)
- [Apple: Swift for Different Platforms](https://www.swift.org/blog/platform-support-announcement/)
- [WWDC 2022: Multi-platform development patterns](https://developer.apple.com/videos/play/wwdc2022/110377)

---

## Shared Code Architecture

### Cross-Platform Module Structure

```swift
// ✅ Correct: Organizing code for multiple platforms

// Core business logic in shared module (platform-agnostic)
// AppCore/Models/User.swift
public struct User: Codable {
    public let id: Int
    public let name: String
    public let email: String
}

// AppCore/Services/UserService.swift
public class UserService {
    private let apiClient: APIClient
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func fetchUser(id: Int) async throws -> User {
        return try await apiClient.fetch(endpoint: "/users/\(id)")
    }
    
    public func updateUser(_ user: User) async throws {
        try await apiClient.post(endpoint: "/users", body: user)
    }
}

// Platform-specific implementations
// iOS/ViewModels/UserViewModel.swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    
    private let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    func loadUser(id: Int) async {
        isLoading = true
        do {
            user = try await userService.fetchUser(id: id)
        } catch {
            print("Error loading user: \(error)")
        }
        isLoading = false
    }
}

// macOS/Views/UserDetailView.swift (separate file for macOS UI)
import SwiftUI

struct UserDetailView: View {
    @StateObject private var viewModel: UserViewModel
    
    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: UserViewModel(userService: userService))
    }
    
    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text(user.name)
                    .font(.title)
                Text(user.email)
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadUser(id: 1)
        }
    }
}
```

**Key Points:**
- Separate business logic (shared) from UI (platform-specific)
- Use async/await for consistent cross-platform APIs
- Keep models in shared code
- Isolate platform-specific frameworks (UIKit, AppKit, etc.)

### Dependency Injection for Platforms

```swift
// ✅ Correct: Platform-specific dependency injection
import AppCore

// DependencyContainer.swift - platform-agnostic protocol
public protocol DependencyContainer {
    func makeUserService() -> UserService
    func makeNetworkClient() -> NetworkClient
}

// iOS/iOSDependencies.swift - iOS-specific implementation
class iOSDependencyContainer: DependencyContainer {
    private let session = URLSession.shared
    
    func makeUserService() -> UserService {
        UserService(apiClient: iOSAPIClient(session: session))
    }
    
    func makeNetworkClient() -> NetworkClient {
        iOSNetworkClient(session: session)
    }
}

// macOS/macOSDependencies.swift - macOS-specific implementation
class macOSDependencyContainer: DependencyContainer {
    private let session = URLSession.shared
    
    func makeUserService() -> UserService {
        UserService(apiClient: macOSAPIClient(session: session))
    }
    
    func makeNetworkClient() -> NetworkClient {
        macOSNetworkClient(session: session)
    }
}

// Usage
let container: DependencyContainer
#if os(iOS)
container = iOSDependencyContainer()
#elseif os(macOS)
container = macOSDependencyContainer()
#endif

let userService = container.makeUserService()
```

---

## Platform Detection

### Compile-Time Conditionals

```swift
// ✅ Correct: Using compile-time platform checking

// iOS-only code
#if os(iOS)
import UIKit

class iOSViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
#endif

// macOS-only code
#if os(macOS)
import AppKit

class macOSWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "My App"
    }
}
#endif

// iOS and watchOS
#if os(iOS) || os(watchOS)
print("Running on watch or iPhone")
#endif

// All platforms except tvOS
#if !os(tvOS)
print("Not running on Apple TV")
#endif
```

### Runtime Platform Detection

```swift
// ✅ Correct: Runtime platform-specific behavior
import Foundation

struct PlatformInfo {
    static var isPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }
    
    static var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    static var isWatch: Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }
}

// Usage
if PlatformInfo.isPhone {
    // iPhone-specific layout
}

if PlatformInfo.isPad {
    // iPad-specific layout with larger screens
}
```

---

## Adaptive UI

### Size Class Adaptation

```swift
// ✅ Correct: Responsive layout with size classes
import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone or portrait iPad - single column
            VStack {
                primaryContent
                secondaryContent
            }
        } else {
            // iPad or Mac - side by side
            HStack(spacing: 20) {
                primaryContent
                secondaryContent
            }
        }
    }
    
    var primaryContent: some View {
        VStack {
            Text("Primary Content")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
    }
    
    var secondaryContent: some View {
        VStack {
            Text("Secondary Content")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
    }
}
```

### Responsive Font and Spacing

```swift
// ✅ Correct: Adaptive typography
import SwiftUI

struct AdaptiveText: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    
    var body: some View {
        VStack(spacing: adaptiveSpacing) {
            Text("Title")
                .font(adaptiveFont(.title))
            
            Text("Subtitle")
                .font(adaptiveFont(.body))
        }
        .padding(adaptivePadding)
    }
    
    private var adaptiveSpacing: CGFloat {
        hSizeClass == .compact ? 8 : 16
    }
    
    private var adaptivePadding: CGFloat {
        hSizeClass == .compact ? 16 : 32
    }
    
    private func adaptiveFont(_ style: Font.TextStyle) -> Font {
        hSizeClass == .compact ? .system(size: 14) : .system(size: 18)
    }
}
```

---

## Platform-Specific APIs

### Graceful Feature Gates

```swift
// ✅ Correct: Handling platform-specific features

struct CameraManager {
    func startCamera() throws {
        #if os(iOS)
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraError.noDeviceAvailable
        }
        // Start camera on iOS
        #elseif os(macOS)
        // macOS camera implementation
        #else
        throw CameraError.notSupported
        #endif
    }
    
    func takeScreenshot() {
        #if os(iOS) || os(tvOS)
        UIGraphicsBeginImageContextWithOptions(screenSize, false, 0)
        // iOS screenshot
        UIGraphicsEndImageContext()
        
        #elseif os(macOS)
        NSScreen.main?.captureAsImage()
        
        #elseif os(watchOS)
        WKInterfaceDevice.current().screenBrightness = 1.0
        #endif
    }
}

enum CameraError: Error {
    case noDeviceAvailable
    case notSupported
}
```

### Availability Checking

```swift
// ✅ Correct: Using @available for version-specific features
import UIKit

class ModernViewController: UIViewController {
    func setupUI() {
        if #available(iOS 15, macOS 12, *) {
            // Use modern SwiftUI
            let hostingController = UIHostingController(rootView: ModernView())
            addChild(hostingController)
        } else {
            // Fallback to UIKit
            let legacy = LegacyViewController()
            addChild(legacy)
        }
    }
    
    @available(iOS 14, *)
    func useWidgetKit() {
        // WidgetKit only available on iOS 14+
    }
}
```

---

## watchOS Development

### Watch App Architecture

```swift
// ✅ Correct: watchOS-specific app structure
import WatchKit
import SwiftUI

@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Count: \(count)")
                .font(.title3)  // Watch uses smaller fonts
            
            Button(action: { count += 1 }) {
                Text("Tap")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// Watch-specific: Handle scroll
struct WatchListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {  // No spacing needed
                ForEach(0..<100, id: \.self) { index in
                    Text("Item \(index)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(index % 2 == 0 ? Color.blue : Color.clear)
                }
            }
        }
    }
}
```

### Watch Connectivity

```swift
// ✅ Correct: Communicating between iPhone and Watch
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func sendDataToWatch(_ data: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("Error sending to watch: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            print("Received from watch: \(message)")
        }
    }
}
```

---

## tvOS Development

### TV-Safe Areas and Focus

```swift
// ✅ Correct: tvOS remote handling and focus management
import SwiftUI

struct TVView: View {
    @State private var focusedItem: Int = 0
    
    var body: some View {
        VStack(spacing: 30) {
            ForEach(0..<3, id: \.self) { index in
                Button(action: { handleSelection(index) }) {
                    Text("Option \(index)")
                        .font(.title)
                        .frame(width: 300, height: 100)
                        .background(focusedItem == index ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .focusable(true) { isFocused in
                    if isFocused {
                        focusedItem = index
                    }
                }
            }
        }
        .padding(60)  // TV safe area padding
    }
    
    func handleSelection(_ index: Int) {
        // Handle remote select button
        print("Selected option \(index)")
    }
}

// Handle remote gestures
#if os(tvOS)
extension UIGestureRecognizer {
    // tvOS uses tap gesture recognizer for remote
    // SwiftUI handles this automatically with .onTapGesture()
}
#endif
```

---

## ✅ Best Practices

### Practice 1: Share Business Logic, Not UI
**DO:**
```swift
// ✅ Shared
public class UserRepository {
    public func fetchUsers() async throws -> [User] { }
}

// Platform-specific
#if os(iOS)
class iOSUserView: UIViewController { }
#elseif os(macOS)
class macOSUserView: NSViewController { }
#endif
```

### Practice 2: Use Protocol-Based Abstractions
**DO:**
```swift
protocol Logger {
    func log(_ message: String)
}

class ConsoleLogger: Logger {
    func log(_ message: String) {
        print(message)
    }
}

// Can swap implementations per platform
```

### Practice 3: Separate Framework Imports
**DO:**
```swift
// ✅ Core module has no platform imports
public class DataManager { }

// ✅ Platform-specific modules import their frameworks
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Mixing Platform Code in Shared Modules
**WRONG:**
```swift
// ❌ Can't compile on all platforms
public class DataProcessor {
    func process() {
        let vc = UIViewController()  // Only iOS!
    }
}
```

**CORRECT:**
```swift
// ✅ Platform-agnostic
public class DataProcessor {
    public func process() { }
}

// Platform-specific
#if os(iOS)
class iOSDataController: UIViewController {
    let processor = DataProcessor()
}
#endif
```

### Mistake 2: Assuming All Platforms Have Same Screen Size
**WRONG:**
```swift
// ❌ Hardcoded for iPhone
let width: CGFloat = 375
let height: CGFloat = 812
```

**CORRECT:**
```swift
// ✅ Adaptive
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    
    var body: some View {
        VStack {
            if hSizeClass == .compact {
                CompactLayout()
            } else {
                RegularLayout()
            }
        }
    }
}
```

### Mistake 3: Not Testing on Actual Devices
**WRONG:**
```swift
// ❌ Simulator-only testing misses real issues
// Simulator != Real device for:
// - Performance
// - Screen sizes
// - Input methods (watch crown, TV remote)
```

**CORRECT:**
```swift
// ✅ Test on actual devices regularly
// iPhone, iPad, Mac, Apple Watch, Apple TV
// Different screen sizes and orientations
```

### Mistake 4: Ignoring Platform Conventions
**WRONG:**
```swift
// ❌ iPhone UI patterns on macOS
struct Settings: View {
    var body: some View {
        NavigationStack {  // iPhone pattern
            List { }
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Platform-native patterns
#if os(iOS)
struct Settings: View {
    var body: some View {
        NavigationStack { List { } }
    }
}
#elseif os(macOS)
struct Settings: View {
    var body: some View {
        VStack { }  // macOS prefers vertical, not stacked nav
    }
}
#endif
```

---

## 🔗 Related Topics
- [Architecture Patterns](../02-architecture/design-patterns.md) - Multi-platform design
- [SwiftUI Basics](swiftui-basics.md) - Cross-platform UI framework
- [Async Concurrency](async-concurrency.md) - Async/await across platforms
- [App Lifecycle](../04-app-lifecycle/app-store-and-release.md) - Deployment considerations
- [Performance Optimization](performance-optimization.md) - Platform-specific optimization
