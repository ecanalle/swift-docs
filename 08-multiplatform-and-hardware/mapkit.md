# MapKit - Location Display and Mapping

## Overview

MapKit provides native map display, annotations, and location visualization. It integrates with Core Location for GPS-based features.

## Main Topics

- [Basic Map Display](#basic-map-display)
- [Annotations](#annotations)
- [Overlays](#overlays)
- [Route Planning](#route-planning)
- [SwiftUI Integration](#swiftui-integration)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [MapKit](https://developer.apple.com/documentation/mapkit)

---

## Basic Map Display

### Simple Map View

```swift
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
    }
    
    private func setupMap() {
        // Set initial region
        let initialLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let region = MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Zoom Controls
    
    func zoomToLevel(_ level: Double) {
        var region = mapView.region
        region.span.latitudeDelta = level
        region.span.longitudeDelta = level
        mapView.setRegion(region, animated: true)
    }
    
    func zoomIn() {
        var region = mapView.region
        region.span.latitudeDelta /= 2
        region.span.longitudeDelta /= 2
        mapView.setRegion(region, animated: true)
    }
    
    func zoomOut() {
        var region = mapView.region
        region.span.latitudeDelta *= 2
        region.span.longitudeDelta *= 2
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Map Type
    
    func setMapType(_ type: MKMapType) {
        mapView.mapType = type
        // Options: .standard, .satellite, .hybrid, .satelliteFlyover, .hybridFlyover
    }
}
```

### Tracking User Location

```swift
import MapKit
import CoreLocation

class UserTrackingMapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
        setupMapView()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    func startUserTracking() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, 
                       didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Center map on user
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        mapView.setRegion(region, animated: true)
    }
}

extension UserTrackingMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, 
                didUpdate userLocation: MKUserLocation) {
        print("User at: \(userLocation.coordinate)")
    }
}
```

---

## Annotations

### Basic Annotations

```swift
import MapKit

class AnnotationMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        addAnnotations()
    }
    
    private func addAnnotations() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        annotation.title = "San Francisco"
        annotation.subtitle = "City by the Bay"
        
        mapView.addAnnotation(annotation)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, 
                viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Skip user location
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "marker"
        var annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier
        ) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.markerTintColor = .red
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, 
                didSelect view: MKAnnotationView) {
        print("Selected: \(view.annotation?.title ?? "")")
    }
}
```

### Custom Annotations

```swift
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var imageName: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, imageName: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
    }
}

class CustomAnnotationViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    func addCustomAnnotation() {
        let annotation = CustomAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            title: "Custom Location",
            subtitle: "With custom image",
            imageName: "star"
        )
        
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, 
                viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotation else { return nil }
        
        let identifier = "customPin"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if view == nil {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view?.image = UIImage(systemName: annotation.imageName ?? "pin")
        }
        
        return view
    }
}
```

---

## Overlays

### Polylines and Polygons

```swift
import MapKit

class OverlayMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    func drawPolyline() {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712),
            CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        ]
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }
    
    func drawCircle(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        let circle = MKCircle(center: center, radius: radius)
        mapView.addOverlay(circle)
    }
    
    func drawPolygon() {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394)
        ]
        
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, 
                rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        }
        
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            renderer.strokeColor = .blue
            renderer.lineWidth = 2
            return renderer
        }
        
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.green.withAlphaComponent(0.2)
            renderer.strokeColor = .green
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
```

---

## Route Planning

### Directions and Routes

```swift
import MapKit

class DirectionsViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    func calculateRoute(from startCoordinate: CLLocationCoordinate2D, 
                       to endCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, let route = response.routes.first else {
                print("No route found")
                return
            }
            
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            
            print("Distance: \(route.distance / 1000) km")
            print("Duration: \(route.expectedTravelTime / 60) minutes")
        }
    }
}
```

---

## SwiftUI Integration

### MapView Wrapper

```swift
import SwiftUI
import MapKit

struct MapViewContainer: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {}
}

struct SwiftUIMapView: View {
    let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    var body: some View {
        MapViewContainer(coordinate: coordinate)
            .ignoresSafeArea()
    }
}
```

---

## 🎯 Best Practices

### 1. Request Location Permission
```swift
// ✅ Always check before accessing user location
locationManager.requestWhenInUseAuthorization()

// ❌ Assume permission granted
mapView.showsUserLocation = true
```

### 2. Manage Annotation Views
```swift
// ✅ Dequeue and reuse views
let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

// ❌ Create new views every time
let view = MKAnnotationView()
```

### 3. Update Region Responsibly
```swift
// ✅ Animate when user initiates
mapView.setRegion(region, animated: true)

// ❌ Constantly update region
// Disrupts user interaction
```

---

## ❌ Common Mistakes

### Mistake 1: Not Requesting Location Permission

**WRONG:**
```swift
// ❌ No permission request
mapView.showsUserLocation = true
```

**CORRECT:**
```swift
// ✅ Request first
locationManager.requestWhenInUseAuthorization()
mapView.showsUserLocation = true
```

---

## Related Topics

- [Core Location - GPS](core-location.md)
- [Annotations and Overlays](.)
- [SwiftUI Views](../05-features/swiftui-basics.md)

---

**Navigate with maps in your app!**
