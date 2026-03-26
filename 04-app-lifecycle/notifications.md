# Local and Push Notifications

## Overview

Notifications inform users about events outside the app. Local notifications are scheduled by the app; push notifications are sent from a server. Both types enhance user engagement and retention.

## Main Topics

- [Notification Fundamentals](#notification-fundamentals)
- [Local Notifications](#local-notifications)
- [Push Notifications (APNs)](#push-notifications-apns)
- [Notification Handling](#notification-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [User Notifications](https://developer.apple.com/documentation/usernotifications)
- [Remote Notifications](https://developer.apple.com/documentation/usernotifications/remote_notifications)

---

## Notification Fundamentals

### Notification Types

```swift
// Local Notification - Scheduled by app
// - Reminder: "Time to take a break"
// - Alarm: "Alarm is ringing"
// - Scheduled: "Meeting in 15 minutes"

// Push Notification - Sent from server
// - Message: New chat message
// - Update: Content available
// - Critical: Emergency alert
```

### Requesting User Permission

```swift
import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Notification permission granted")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } else if let error = error {
            print("Error requesting permission: \(error)")
        }
    }
}

// Call in AppDelegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestNotificationPermission()
        return true
    }
}
```

### Checking Permission Status

```swift
func checkNotificationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .notDetermined:
            print("Permission not requested yet")
        case .denied:
            print("User denied notification permission")
        case .authorized:
            print("Notifications authorized")
        case .provisional:
            print("Provisional authorization granted")
        case .ephemeral:
            print("Ephemeral authorization granted")
        @unknown default:
            break
        }
    }
}
```

---

## Local Notifications

### Basic Local Notification

```swift
import UserNotifications

func scheduleLocalNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Reminder"
    content.body = "Don't forget your meeting!"
    content.sound = .default
    
    // Trigger after 5 seconds
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: "reminder-1", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling notification: \(error)")
        } else {
            print("Notification scheduled")
        }
    }
}
```

### Calendar-Based Notification

```swift
func scheduleDailyNotification(hour: Int, minute: Int) {
    let content = UNMutableNotificationContent()
    content.title = "Daily Reminder"
    content.body = "Check your tasks for today"
    content.sound = .default
    
    // Trigger every day at specific time
    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error: \(error)")
        }
    }
}

// Schedule tomorrow at 9 AM
scheduleDailyNotification(hour: 9, minute: 0)
```

### Location-Based Notification

```swift
import CoreLocation

func scheduleLocationNotification(latitude: Double, longitude: Double) {
    let content = UNMutableNotificationContent()
    content.title = "Location Alert"
    content.body = "You're near the store!"
    content.sound = .default
    
    let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radius: 100,  // 100 meters
        identifier: "store-location"
    )
    region.notifyOnEntry = true
    region.notifyOnExit = false
    
    let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
    let request = UNNotificationRequest(identifier: "location-1", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error: \(error)")
        }
    }
}
```

### Notification Customization

```swift
import UserNotifications

func createCustomNotification() {
    let content = UNMutableNotificationContent()
    content.title = "New Message"
    content.body = "John: Hey, how are you?"
    content.sound = .default
    
    // Badge count
    content.badge = NSNumber(value: 3)
    
    // Custom data
    content.userInfo = [
        "messageID": "msg-123",
        "senderID": "user-456"
    ]
    
    // Add attachment (image, video, audio)
    if let url = Bundle.main.url(forResource: "notification-image", withExtension: "jpg"),
       let attachment = try? UNNotificationAttachment(identifier: "image", url: url) {
        content.attachments = [attachment]
    }
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: "message-1", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error: \(error)")
        }
    }
}
```

---

## Push Notifications (APNs)

### Device Token Registration

```swift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Called when device token is received
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(token)")
        
        // Send token to server
        sendTokenToServer(token)
    }
    
    // Called if registration fails
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func sendTokenToServer(_ token: String) {
        // POST token to backend
    }
}
```

### Handling Push Notifications

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Process notification
        print("Notification received in foreground: \(userInfo)")
        
        // Show banner even in foreground (iOS 14+)
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo["messageID"] as? String {
            // Navigate to message
            navigateToMessage(messageID)
        }
        
        completionHandler()
    }
    
    func navigateToMessage(_ id: String) {
        print("Navigating to message: \(id)")
    }
}
```

---

## Notification Handling

### Managing Notifications

```swift
import UserNotifications

// Get pending notifications
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    for request in requests {
        print("Pending: \(request.identifier) - \(request.content.title)")
    }
}

// Remove specific notification
UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reminder-1"])

// Remove all notifications
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

// Get delivered notifications
UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
    for notification in notifications {
        print("Delivered: \(notification.request.identifier)")
    }
}

// Remove delivered notification
UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["message-1"])
```

### Rich Notifications

```swift
func scheduleRichNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Message from Sarah"
    content.body = "Check this out!"
    
    // Add action buttons
    let replyAction = UNNotificationAction(
        identifier: "REPLY",
        title: "Reply",
        options: [.authenticationRequired]
    )
    let likeAction = UNNotificationAction(
        identifier: "LIKE",
        title: "Like",
        options: []
    )
    
    let category = UNNotificationCategory(
        identifier: "MESSAGE_CATEGORY",
        actions: [replyAction, likeAction],
        intentIdentifiers: [],
        options: []
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([category])
    content.categoryIdentifier = "MESSAGE_CATEGORY"
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: "rich-message", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request)
}

// Handle action response
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "REPLY":
            print("User tapped Reply")
        case "LIKE":
            print("User tapped Like")
        default:
            break
        }
        completionHandler()
    }
}
```

---

## 🎯 Best Practices

### 1. Request Permission First
```swift
// ✅ Always request before scheduling
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
    if granted {
        scheduleLocalNotification()
    }
}

// ❌ Don't assume permission
scheduleLocalNotification()  // May fail silently
```

### 2. Use Meaningful Identifiers
```swift
// ✅ Clear identification
let request = UNNotificationRequest(identifier: "user-123-reminder", content: content, trigger: trigger)

// ❌ Generic identifier
let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
```

### 3. Test on Device
```swift
// Notifications may behave differently on simulator
// Always test on actual device for push notifications
```

---

## ❌ Common Mistakes

### Mistake 1: Not Requesting Permission

**WRONG:**
```swift
// ❌ Notifications won't appear
scheduleLocalNotification()
```

**CORRECT:**
```swift
// ✅ Request first
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
    if granted {
        scheduleLocalNotification()
    }
}
```

---

### Mistake 2: Not Registering for Remote Notifications

**WRONG:**
```swift
// ❌ Push notifications won't be received
// Missing: UIApplication.shared.registerForRemoteNotifications()
```

**CORRECT:**
```swift
// ✅ Register after permission granted
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
```

---

### Mistake 3: Missing Delegate

**WRONG:**
```swift
// ❌ No handler for notifications
// setDelegate not called
```

**CORRECT:**
```swift
// ✅ Set delegate in AppDelegate
UNUserNotificationCenter.current().delegate = self
```

---

## Related Topics

- [Background Tasks](app-lifecycle.md)
- [AppDelegate](app-lifecycle.md)
- [User Engagement](../09-testing-debugging/testing.md)

---

**Master notifications to keep users engaged with your app!**
