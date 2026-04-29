# Geolocation & Maps - Core Location & MapKit 🎯

## Overview
Build location-aware apps with Core Location for GPS positioning and MapKit for interactive maps. From displaying user locations to routing and region monitoring, learn to integrate powerful mapping and positioning capabilities.

## Main Topics
- [Core Location Basics](#core-location-basics) - Getting user location
- [MapKit Fundamentals](#mapkit-fundamentals) - Displaying maps
- [Annotations & Overlays](#annotations--overlays) - Adding content to maps
- [Routing & Navigation](#routing--navigation) - Directions and paths
- [Geofencing](#geofencing) - Location-based triggers
- [Best Practices](#-best-practices) - Location accuracy
- [Common Mistakes](#-common-mistakes-anti-patterns) - Privacy pitfalls

## Official Documentation
- [Apple: Core Location](https://developer.apple.com/documentation/corelocation)
- [Apple: MapKit](https://developer.apple.com/documentation/mapkit)
- [WWDC 2022: What's new in MapKit](https://developer.apple.com/videos/play/wwdc2022/10035)

---

## Core Location Basics

### Requesting User Location

```swift
// ✅ Correct: Proper location permission handling
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            
        case .notDetermined:
            // Request permission first
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            print("Location access denied")
            
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        onLocationUpdate?(location)
        print("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Stop updating to save battery
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// Info.plist requirements:
// NSLocationWhenInUseUsageDescription: "We need your location for..."
// NSLocationAlwaysAndWhenInUseUsageDescription: "Background location needed for..."
```

### Geocoding and Reverse Geocoding

```swift
// ✅ Correct: Converting between coordinates and addresses
import CoreLocation

class GeocodingService {
    let geocoder = CLGeocoder()
    
    func getAddressFromCoordinate(_ coordinate: CLLocationCoordinate2D,
                                 completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude,
                                 longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            // Format address
            var components: [String] = []
            if let thoroughfare = placemark.thoroughfare {
                components.append(thoroughfare)
            }
            if let locality = placemark.locality {
                components.append(locality)
            }
            
            let address = components.joined(separator: ", ")
            completion(address)
        }
    }
    
    func getCoordinateFromAddress(_ address: String,
                                 completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
}

// Usage
let service = GeocodingService()
let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
service.getAddressFromCoordinate(coordinate) { address in
    print("Address: \(address ?? "Unknown")")
}
```

---

## MapKit Fundamentals

### Displaying Maps with SwiftUI

```swift
// ✅ Correct: SwiftUI map integration
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        
        // Set initial region
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        map.setRegion(region, animated: true)
        
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        uiView.setRegion(region, animated: true)
    }
}

// Usage
struct MapContainer: View {
    var body: some View {
        MapView(
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
    }
}
```

### Map Configuration

```swift
// ✅ Correct: Setting map style and behavior
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set map type
        mapView.mapType = .satellite  // .standard, .satellite, .hybrid, .mutedStandard
        
        // Enable user interaction
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
        // Set initial zoom level
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
        
        // Set delegate
        mapView.delegate = self
    }
}

extension MapViewController: MKMapViewDelegate {
    // Handle map interactions
}
```

---

## Annotations & Overlays

### Adding Custom Annotations

```swift
// ✅ Correct: Custom map annotations
import MapKit

class PlaceAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var imageName: String?
    
    init(coordinate: CLLocationCoordinate2D, 
         title: String, 
         subtitle: String = "",
         imageName: String = "") {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
    }
}

class MapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    func addAnnotations() {
        let restaurants = [
            PlaceAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                title: "Restaurant A",
                subtitle: "Italian Cuisine",
                imageName: "fork.knife"
            ),
            PlaceAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 40.7150, longitude: -74.0070),
                title: "Restaurant B",
                subtitle: "French Cuisine",
                imageName: "fork.knife"
            )
        ]
        
        mapView.addAnnotations(restaurants)
    }
    
    // Customize annotation view
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? PlaceAnnotation else { return nil }
        
        let identifier = "PlaceAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // Add info button
            let infoButton = UIButton(type: .infoLight)
            annotationView?.rightCalloutAccessoryView = infoButton
        } else {
            annotationView?.annotation = annotation
        }
        
        // Custom appearance
        if let markerView = annotationView as? MKMarkerAnnotationView {
            markerView.markerTintColor = .blue
            markerView.glyphImage = UIImage(systemName: annotation.imageName ?? "mappin")
        }
        
        return annotationView
    }
}
```

### Map Overlays

```swift
// ✅ Correct: Drawing overlays on map
import MapKit

class OverlayViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    func addPolygon() {
        // Define polygon coordinates
        let coords = [
            CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            CLLocationCoordinate2D(latitude: 40.7150, longitude: -74.0070),
            CLLocationCoordinate2D(latitude: 40.7180, longitude: -74.0050),
            CLLocationCoordinate2D(latitude: 40.7160, longitude: -74.0040)
        ]
        
        let polygon = MKPolygon(coordinates: coords, count: coords.count)
        mapView.addOverlay(polygon)
    }
    
    func addCircle() {
        let circle = MKCircle(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            radius: 500  // meters
        )
        mapView.addOverlay(circle)
    }
    
    // Render overlays
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.2)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
```

---

## Routing & Navigation

### Getting Directions

```swift
// ✅ Correct: Route calculation
import MapKit

class NavigationService {
    func getDirections(from: CLLocationCoordinate2D,
                      to: CLLocationCoordinate2D,
                      completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error)")
                completion(nil)
                return
            }
            
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            print("Distance: \(route.distance) meters")
            print("Duration: \(route.expectedTravelTime) seconds")
            
            completion(route)
        }
    }
}

// Display route on map
class RouteViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    func displayRoute(_ route: MKRoute) {
        mapView.addOverlay(route.polyline, level: .aboveRoads)
        
        // Fit map to show route
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
            animated: true
        )
    }
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
}
```

---

## Geofencing

### Region Monitoring

```swift
// ✅ Correct: Geofence setup and monitoring
import CoreLocation

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var onRegionEnter: ((String) -> Void)?
    var onRegionExit: ((String) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    func startMonitoring(for region: CLCircularRegion) {
        // Check if geofencing is available
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            print("Started monitoring region: \(region.identifier)")
        } else {
            print("Geofencing not available")
        }
    }
    
    func stopMonitoring(for region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        onRegionEnter?(region.identifier)
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        onRegionExit?(region.identifier)
    }
}

// Usage
let geofence = GeofenceManager()
let region = CLCircularRegion(
    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    radius: 100,  // 100 meters
    identifier: "home"
)

geofence.startMonitoring(for: region)

geofence.onRegionEnter = { regionID in
    print("Entered \(regionID)")
}
```

---

## ✅ Best Practices

### Practice 1: Use Precise Location Only When Needed
**DO:**
```swift
// ✅ Request reduced accuracy by default
locationManager.accuracyAuthorization = .reducedAccuracy

// ✅ Only upgrade to precise when necessary
if needsPreciseLocation {
    locationManager.accuracyAuthorization = .fullAccuracy
}
```

### Practice 2: Stop Updates to Save Battery
**DO:**
```swift
// ✅ Stop when not needed
locationManager.stopUpdatingLocation()

// ✅ Use significant location changes for background
locationManager.startMonitoringSignificantLocationChanges()
```

### Practice 3: Respect Privacy Settings
**DO:**
```swift
// ✅ Check authorization before using location
let status = CLLocationManager.authorizationStatus()
if status == .authorizedAlways || status == .authorizedWhenInUse {
    // Use location
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Requesting .always Without Justification
**WRONG:**
```swift
// ❌ Users likely to deny
locationManager.requestAlwaysAuthorization()
```

**CORRECT:**
```swift
// ✅ Start with .whenInUse
locationManager.requestWhenInUseAuthorization()
```

### Mistake 2: Not Stopping Location Updates
**WRONG:**
```swift
// ❌ Drains battery continuously
locationManager.startUpdatingLocation()
// Never stops
```

**CORRECT:**
```swift
// ✅ Stop when done
func locationManager(_ manager: CLLocationManager,
                    didUpdateLocations: [CLLocation]) {
    manager.stopUpdatingLocation()  // Stop after update
}
```

### Mistake 3: Hardcoding Location Data
**WRONG:**
```swift
// ❌ Not testable
let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
```

**CORRECT:**
```swift
// ✅ Injectable for testing
protocol LocationProvider {
    var currentLocation: CLLocationCoordinate2D { get }
}
```

---

## 🔗 Related Topics
- [App Lifecycle](../04-app-lifecycle/app-store-and-release.md) - Background modes
- [Permissions & Privacy](../07-advanced/permissions-and-security.md) - Location permissions
- [Performance Optimization](../07-advanced/performance-optimization.md) - Battery life
- [Notifications](../04-app-lifecycle/notifications.md) - Location-based alerts
