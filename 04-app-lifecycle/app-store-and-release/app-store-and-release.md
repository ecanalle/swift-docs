# App Lifecycle Basics

## Overview

Understanding the iOS app lifecycle—from launch through background execution to termination—is crucial for building responsive apps that respect user experience and system resources.

## Main Topics

- [Launch Sequence](#launch-sequence)
- [App States](#app-states)
- [SceneDelegate and UIWindowSceneDelegate](#scenedelegate-and-uiwindowscenedelegate)
- [View Controller Lifecycle](#view-controller-lifecycle)
- [Managing Background Tasks](#managing-background-tasks)
- [App Termination](#app-termination)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [App Lifecycle - Apple](https://developer.apple.com/documentation/uikit/uiapplicationdelegate)
- [WWDC: App Lifecycle](https://developer.apple.com/videos/play/wwdc2021/10012/)

---

## Launch Sequence

### App Launch Flow

```
1. System launches app
2. Main entry point (main.swift or @main)
3. UIApplicationMain() called
4. AppDelegate.application(_:didFinishLaunchingWithOptions:)
5. SceneDelegate.scene(_:willConnectTo:options:)
6. First view controller displayed
```

### AppDelegate Setup

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize networking, analytics, etc.
        // This runs ONCE when app launches
        
        analytics.trackAppLaunch()
        database.initialize()
        
        return true  // true = continue launching, false = cancel
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // App is active and visible
        // Resume animations, timers, etc.
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // App is about to become inactive
        // Pause ongoing tasks
    }
}
```

---

## App States

### App Lifecycle States

```swift
enum UIApplicationState {
    case active        // App is in foreground and user can interact
    case inactive      // App is in foreground but not receiving events
    case background    // App is in background
}

// Monitor state changes
class AppLifecycleMonitor {
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc func appDidBecomeActive() {
        print("Active - resume animations")
    }
    
    @objc func appWillResignActive() {
        print("Inactive - pause animations")
    }
    
    @objc func appDidEnterBackground() {
        print("Background - cleanup and prepare for termination")
    }
    
    @objc func appWillEnterForeground() {
        print("Foreground - resume work")
    }
}
```

---

## SceneDelegate and UIWindowSceneDelegate

Modern app lifecycle uses SceneDelegate:

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    // Called when scene is created (app launch or when coming from background)
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Setup initial view controller
        let rootViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Handle deep links from connectionOptions
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }
    
    // Scene entered foreground
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Resume any tasks
    }
    
    // Scene is visible to user
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Refresh data, animations
    }
    
    // Scene about to leave foreground
    func sceneWillResignActive(_ scene: UIScene) {
        // Save state, pause animations
    }
    
    // Scene entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Heavy cleanup before potential termination
    }
    
    // Handle deep links
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }
    
    private func handleUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                // Handle deep link
                handleDeepLink(url)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Parse URL and navigate
    }
}
```

---

## View Controller Lifecycle

### UIViewController Lifecycle Events

```swift
class MyViewController: UIViewController {
    
    // MARK: - Initialization
    // Called when view controller is created
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize UI and set up observers
        setupUI()
        loadData()
    }
    
    // Called just before view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Resume work, refresh data
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // Called when view is visible
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start animations, timers
        startRefreshTimer()
    }
    
    // Called just before view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause animations, stop timers
        stopRefreshTimer()
    }
    
    // Called when view is no longer visible
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Cleanup if needed
    }
    
    // MARK: - Cleanup
    // Called when view controller is removed from memory
    deinit {
        // Remove observers, cleanup resources
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Rotation
    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Handle orientation change
    }
}
```

### Complete Lifecycle Diagram

```
viewDidLoad
    ↓
viewWillAppear(true)
    ↓
viewDidAppear(true)
    ├─ User interacts
    ├─ Another VC pushed
    ↓
viewWillDisappear(true)
    ↓
viewDidDisappear(true)
    ├─ VC is now invisible
    ├─ When back button pressed
    ↓
viewWillAppear(false)
    ↓
viewDidAppear(false)
    ├─ User interacts again
    ↓
viewWillDisappear(false)  [Final]
    ↓
viewDidDisappear(false)
    ↓
deinit  [Memory released]
```

---

## Managing Background Tasks

### Background Task Expiration

```swift
class DataSyncManager {
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    func startBackgroundTask() {
        // Start background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            // Called when time expires or background task ends
            self?.endBackgroundTask()
        }
        
        // Perform work
        performDataSync()
    }
    
    func performDataSync() {
        // Must complete within ~10 seconds
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            // Sync data
            self.syncData()
            
            // Always end the background task
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}
```

### Background Modes

```swift
// In Info.plist or app capabilities:
// - Audio, Airplay, and Picture in Picture
// - Location updates
// - Remote notifications (push)
// - etc.

// Example: Location updates in background
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
        // Location updated in background
        for location in locations {
            print("Location: \(location.coordinate)")
        }
    }
}
```

---

## App Termination

### Saving State Before Termination

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func applicationWillTerminate(_ application: UIApplication) {
        // LAST CHANCE to save data before app is killed
        // Usually called when:
        // - User force-quits app
        // - Device memory is critical
        // - System shutdown
        
        saveAppState()
        saveDataToPersistentStorage()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Better place to save state (called more reliably)
        saveAppState()
    }
    
    private func saveAppState() {
        let state = AppState(
            lastViewedScreen: currentScreen,
            userData: userData,
            lastSyncTime: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: "AppState")
        } catch {
            print("Failed to save state: \(error)")
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Do Heavy Work in AppDelegate/SceneDelegate
- Setup services once at launch
- Don't repeat initialization

### 2. Handle State Changes Properly
- Save state when moving to background
- Restore state when returning to foreground
- Resume/pause work appropriately

### 3. Clean Up Resources
- Remove observers in deinit
- Cancel network requests when VC disappears
- Stop timers and animations

### 4. Use Proper Threading
- Update UI on main thread
- Do heavy work on background threads
- Use DispatchQueue appropriately

### 5. Test All Transitions
- Test app launch
- Test backgrounding (lock device)
- Test app termination (force quit)
- Test deep links

---

## ❌ Common Mistakes

### Mistake 1: Heavy Work in viewDidLoad

**WRONG:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    loadDataFromNetwork()   // Blocks UI
    processLargeDataset()   // Freezes app
}
```

**CORRECT:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    downloadDataInBackground()
}

private func downloadDataInBackground() {
    DispatchQueue.global(qos: .userInitiated).async {
        self.loadDataFromNetwork()
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
}
```

---

### Mistake 2: Not Handling viewWillAppear

**WRONG:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    refreshData()  // Only called once!
}
```

**CORRECT:**
```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshData()  // Called every time VC appears
}
```

---

### Mistake 3: Memory Leaks in Observers

**WRONG:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(update), 
                                          name: NIL, object: nil)
    // Never removed - memory leak!
}
```

**CORRECT:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(update),
                                          name: UIApplication.didBecomeActiveNotification,
                                          object: nil)
}

deinit {
    NotificationCenter.default.removeObserver(self)
}
```

---

## Related Topics

- [ViewControllers and Navigation](uiviewcontroller-basics.md)
- [Background Tasks](../../05-features/background-tasks.md)
- [State Preservation](state-preservation.md)

---

**Master the app lifecycle to build stable, responsive apps!**
