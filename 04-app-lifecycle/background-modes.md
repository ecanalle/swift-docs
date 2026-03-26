# Background Modes and Tasks - iOS Background Processing

## Overview

Background modes allow apps to perform critical tasks when backgrounded. iOS enforces strict limits on background execution time and resources.

## Main Topics

- [Background App Refresh](#background-app-refresh)
- [Location Updates](#location-updates-background)
- [Audio and Media](#audio-and-media)
- [VoIP and Calls](#voip-and-calls)
- [Background Processing](#background-processing)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## Background App Refresh

### Requesting Background Activity

```swift
import BackgroundTasks
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.app.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        scheduleAppRefresh()
        return true
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15)  // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()  // Reschedule
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "AppRefresh") {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        let operation = BlockOperation {
            // Perform refresh work
            self.fetchData()
            
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        task.expirationHandler = {
            queue.cancelAllOperations()
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        queue.addOperation(operation)
    }
    
    func fetchData() {
        // Lightweight data fetch
        print("Fetching data in background")
    }
}
```

### Background Processing Task

```swift
import BackgroundTasks

class DataSyncManager {
    static let identifier = "com.example.app.processing"
    
    static func registerBackgroundProcessing() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
    }
    
    static func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background processing scheduled")
        } catch {
            print("Failed to schedule: \(error)")
        }
    }
    
    static func handleBackgroundProcessing(task: BGProcessingTask) {
        scheduleBackgroundProcessing()  // Reschedule
        
        let queue = OperationQueue()
        let operation = BlockOperation {
            self.syncData()
            task.setTaskCompleted(success: true)
        }
        
        task.expirationHandler = {
            queue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }
        
        queue.addOperation(operation)
    }
    
    static func syncData() {
        print("Syncing data in background")
    }
}
```

---

## Location Updates Background

### Continuous Location Monitoring

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Enable background location updates
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func startBackgroundLocationUpdates() {
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update UI or save location
        print("Location: \(location.coordinate)")
        
        // Process in background
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "LocationUpdate") {
            UIApplication.shared.endBackgroundTask($0)
        }
        
        // Handle update
        UIApplication.shared.endBackgroundTask(bgTask)
    }
}
```

### Geofencing

```swift
import CoreLocation

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    func startMonitoringGeofence(coordinate: CLLocationCoordinate2D, radius: Double) {
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: UUID().uuidString
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.delegate = self
        locationManager.startMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        // Send notification
        let content = UNMutableNotificationContent()
        content.title = "Geofence Alert"
        content.body = "You entered a monitored area"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
}
```

---

## Audio and Media

### Audio Playback Background Mode

```swift
import AVFoundation

class AudioPlayer: NSObject {
    let audioEngine = AVAudioEngine()
    
    func setupAudioForBackground() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func playAudioInBackground(url: URL) {
        setupAudioForBackground()
        
        let player = AVPlayer(url: url)
        player.play()
    }
}
```

### Background Audio Update

```swift
import MediaPlayer
import AVFoundation

class NowPlayingManager {
    static let shared = NowPlayingManager()
    
    func updateNowPlaying(title: String, artist: String, duration: TimeInterval, elapsed: TimeInterval) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        // Add remote commands
        setupRemoteTransportControls()
    }
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.handlePlayCommand()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.handlePauseCommand()
            return .success
        }
    }
    
    func handlePlayCommand() {
        print("Play command received")
    }
    
    func handlePauseCommand() {
        print("Pause command received")
    }
}
```

---

## VoIP and Calls

### VoIP Background Mode

```swift
import PushKit
import CallKit

class VoIPManager: NSObject, PKPushRegistryDelegate {
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let callController = CXCallController()
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    
    override init() {
        super.init()
        setupVoIP()
    }
    
    func setupVoIP() {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // Send token to server
        let token = pushCredentials.token
        print("VoIP token: \(token.map { String(format: "%02x", $0) }.joined())")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // Handle incoming call
        let handle = CXHandle(type: .phoneNumber, value: "1234567890")
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = handle
        callUpdate.hasVideo = false
        
        provider.reportNewIncomingCall(with: UUID(), update: callUpdate) { error in
            completion()
        }
    }
}
```

---

## Background Processing

### URLSession Downloads

```swift
import Foundation

class BackgroundDownloadManager: NSObject, URLSessionDelegate {
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.download")
    
    lazy var session: URLSession = {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func downloadInBackground(url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file to persistent location
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("downloaded.file")
        
        try? FileManager.default.moveItem(at: location, to: destinationURL)
    }
}
```

### Background URLSession Upload

```swift
import Foundation

class BackgroundUploadManager: NSObject, URLSessionDelegate {
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.upload")
    
    lazy var session: URLSession = {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func uploadInBackground(fileURL: URL, to endpoint: URL) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Upload error: \(error)")
        } else {
            print("Upload completed successfully")
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Minimize Background Work
```swift
// ✅ Lightweight operations
func performBackgroundWork() {
    // 10-30 seconds max
    let task = URLSessionConfiguration.background(withIdentifier: "light")
}

// ❌ Heavy processing
func performBackgroundWork() {
    for i in 0..<1_000_000 {
        // ... expensive calculations
    }
}
```

### 2. Set Proper Expiration Handlers
```swift
// ✅ Clean up expiring tasks
task.expirationHandler = {
    queue.cancelAllOperations()
    task.setTaskCompleted(success: false)
}

// ❌ Ignore expiration
task.expirationHandler = {}
```

### 3. Request Only Needed Permissions
```swift
// ✅ Request with appropriate modes
backgroundRequest.requiresNetworkConnectivity = true
backgroundRequest.requiresExternalPower = true

// ❌ Unnecessary constraints
backgroundRequest.requiresExternalPower = true  // For lightweight refresh
```

---

## ❌ Common Mistakes

### Mistake 1: Exceeding Background Time Limit

**WRONG:**
```swift
// ❌ App runs out of time
func handleAppRefresh() {
    for i in 0..<10_000_000 {
        processItem(i)
    }
}
```

**CORRECT:**
```swift
// ✅ Monitor remaining time
var backgroundTask = UIApplication.shared.beginBackgroundTask()
defer { UIApplication.shared.endBackgroundTask(backgroundTask) }

// Use remaining time efficiently
let deadline = Date(timeIntervalSinceNow: 25)  // Leave buffer
```

---

### Mistake 2: Assuming Continuous Execution

**WRONG:**
```swift
// ❌ App expects continuous background access
func scheduleWork() {
    Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
        performWork()
    }
}
```

**CORRECT:**
```swift
// ✅ Reschedule for next background window
func handleBackgroundTask() {
    performWork()
    rescheduleNextExecution()
}
```

---

## Related Topics

- [Notifications](./notifications.md)
- [URLSession Networking](../03-networking/rest-api.md)
- [Core Location](../08-multiplatform-hardware/core-location.md)

---

**Master iOS background task execution!**
