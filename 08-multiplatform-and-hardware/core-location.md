# Core Location - GPS and Location Services

## Overview

Core Location provides GPS and location services including geofencing, compass, and location tracking with privacy controls.

## Main Topics

- [Basic Location Tracking](#basic-location-tracking)
- [Geofencing](#geofencing)
- [Compass](#compass)
- [Permission Handling](#permission-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Core Location](https://developer.apple.com/documentation/corelocation)

---

## Basic Location Tracking

### Simple Location Request

```swift
import CoreLocation

class SimpleLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = SimpleLocationManager()
    
    let locationManager = CLLocationManager()
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10  // Minimum 10m change
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, 
                       didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Latitude: \(location.coordinate.latitude)")
        print("Longitude: \(location.coordinate.longitude)")
        print("Altitude: \(location.altitude)")
        print("Accuracy: \(location.horizontalAccuracy)")
        
        onLocationUpdate?(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, 
                       didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        switch status {
        case .denied, .restricted:
            print("Location permission denied")
        case .notDetermined:
            print("Permission not determined")
        case .authorizedWhenInUse:
            print("Permission granted when in use")
        case .authorizedAlways:
            print("Permission granted always")
        case .authorizedAlwaysAndWhenInUse:
            print("Permission granted always and when in use")
        @unknown default:
            break
        }
    }
}
```

### Advanced Location Manager

```swift
import CoreLocation

class AdvancedLocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((Error) -> Void)?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestWhenInUsePermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesAreEnabled()
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    func startTracking() {
        if isLocationServicesEnabled() {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Distance Calculation
    
    func distanceFrom(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        
        let destination = CLLocation(latitude: coordinate.latitude, 
                                    longitude: coordinate.longitude)
        return current.distance(from: destination)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, 
                       didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, 
                       didFailWithError error: Error) {
        onError?(error)
    }
}
```

---

## Geofencing

### Setting Up Geofences

```swift
import CoreLocation

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var onEnter: ((String) -> Void)?
    var onExit: ((String) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func addGeofence(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func removeGeofence(identifier: String) {
        locationManager.monitoredRegions
            .filter { $0.identifier == identifier }
            .forEach { locationManager.stopMonitoring(for: $0) }
    }
    
    func removeAllGeofences() {
        locationManager.monitoredRegions.forEach { region in
            locationManager.stopMonitoring(for: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, 
                       didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        onEnter?(region.identifier)
        sendNotification(title: "Arrived", body: "You entered \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, 
                       didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        onExit?(region.identifier)
        sendNotification(title: "Left", body: "You left \(region.identifier)")
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, 
                                           content: content, 
                                           trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## Compass

### Using Compass Heading

```swift
import CoreLocation

class CompassManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var onHeadingUpdate: ((CLHeading) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func startCompass() {
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopCompass() {
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, 
                       didUpdateHeading newHeading: CLHeading) {
        let magneticHeading = newHeading.magneticHeading
        let trueHeading = newHeading.trueHeading
        let accuracy = newHeading.headingAccuracy
        
        print("Magnetic: \(magneticHeading)°")
        print("True: \(trueHeading)°")
        print("Accuracy: ±\(accuracy)°")
        
        onHeadingUpdate?(newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, 
                       didFailWithError error: Error) {
        print("Heading error: \(error.localizedDescription)")
    }
}
```

---

## Permission Handling

### Complete Permission Flow

```swift
import CoreLocation

class LocationPermissionManager {
    static func checkAndRequestPermission(completion: @escaping (Bool) -> Void) {
        let manager = CLLocationManager()
        
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // First time - request permission
            manager.requestWhenInUseAuthorization()
            completion(false)
            
        case .restricted, .denied:
            // User denied - show settings
            showSettingsAlert()
            completion(false)
            
        case .authorizedWhenInUse, .authorizedAlways, .authorizedAlwaysAndWhenInUse:
            // Already authorized
            completion(true)
            
        @unknown default:
            completion(false)
        }
    }
    
    static func showSettingsAlert() {
        let alert = UIAlertController(
            title: "Location Permission",
            message: "Please enable location in Settings",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
    }
}
```

---

## 🎯 Best Practices

### 1. Request Minimal Permissions
```swift
// ✅ Only request when in use if possible
locationManager.requestWhenInUseAuthorization()

// ❌ Request always if not needed
locationManager.requestAlwaysAuthorization()
```

### 2. Update Info.plist
```swift
// ✅ Add permission descriptions
// NSLocationWhenInUseUsageDescription
// NSLocationAlwaysAndWhenInUseUsageDescription

// ❌ Missing Info.plist entries
// App will crash when requesting permission
```

### 3. Stop Updates When Not Needed
```swift
// ✅ Stop updates to save battery
locationManager.stopUpdatingLocation()

// ❌ Keep location always running
// Drains battery
```

---

## ❌ Common Mistakes

### Mistake 1: Not Checking Authorization

**WRONG:**
```swift
// ❌ No permission check
func startTracking() {
    locationManager.startUpdatingLocation()
}
```

**CORRECT:**
```swift
// ✅ Check before starting
func startTracking() {
    if CLLocationManager.locationServicesAreEnabled() {
        locationManager.startUpdatingLocation()
    }
}
```

---

### Mistake 2: Ignoring Permission Status Changes

**WRONG:**
```swift
// ❌ Never update when permission changes
// App continues to try location updates if revoked
```

**CORRECT:**
```swift
// ✅ Handle status changes
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager.authorizationStatus == .denied {
        locationManager.stopUpdatingLocation()
    }
}
```

---

## Related Topics

- [MapKit Integration](mapkit.md)
- [Background Modes](../04-app-lifecycle/background-modes.md)
- [Notifications](../04-app-lifecycle/notifications.md)

---

**Navigate the world with Core Location!**
