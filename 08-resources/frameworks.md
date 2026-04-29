# Apple Frameworks & Libraries 📚

## Overview

Apple provides comprehensive frameworks covering everything from basic data structures to advanced machine learning. This guide organizes key frameworks by purpose, version availability, and common use cases, helping developers choose the right tool for each task.

## Main Topics
- [Foundation & Core](#foundation--core) - Essential data structures and utilities
- [User Interface](#user-interface) - Building views and apps
- [Networking & Data](#networking--data) - Communication and storage
- [Media & Graphics](#media--graphics) - Audio, video, and rendering
- [Machine Learning & AI](#machine-learning--ai) - Core ML, Vision, Natural Language
- [System Services](#system-services) - Hardware and OS integration
- [Testing & Development](#testing--development) - Quality assurance tools

## Official Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation)
- [Apple Frameworks Overview](https://developer.apple.com/documentation/technologies)
- [WWDC Videos](https://developer.apple.com/videos)
- [Swift Package Index](https://swiftpackageindex.com/)

---

## Foundation & Core

### Core Frameworks

| Framework | Purpose | iOS | macOS | watchOS | tvOS |
|-----------|---------|-----|-------|---------|------|
| **Foundation** | Core data types, collections, file I/O | 2.0+ | 10.0+ | 2.0+ | 9.0+ |
| **Swift** | Standard library, concurrency | 5.0+ | 10.11+ | 2.0+ | 9.0+ |
| **Combine** | Reactive programming, pub/sub | 13.0+ | 10.15+ | 6.0+ | 13.0+ |
| **Structured Concurrency** | async/await, tasks | 13.0+ | 10.15+ | 6.0+ | 13.0+ |

### Key Foundation APIs

```swift
// String & Text Processing
import Foundation

// String manipulation
let text = "Hello, Swift!"
let uppercased = text.uppercased()
let range = text.range(of: "Swift")

// Collections
let array = [1, 2, 3, 4, 5]
let mapped = array.map { $0 * 2 }
let filtered = array.filter { $0 > 2 }

let dictionary = ["name": "Alice", "age": "30"]
for (key, value) in dictionary {
    print("\(key): \(value)")
}

// File I/O
let fileManager = FileManager.default
let documentDirectory = fileManager.urls(
    for: .documentDirectory,
    in: .userDomainMask
).first!

let filePath = documentDirectory.appendingPathComponent("data.txt")
try "Hello".write(to: filePath, atomically: true, encoding: .utf8)
let content = try String(contentsOf: filePath, encoding: .utf8)

// Date & Time
let date = Date()
let formatter = DateFormatter()
formatter.dateStyle = .medium
let formattedDate = formatter.string(from: date)

// JSON Codable
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

let json = """
{"id": 1, "name": "Alice", "email": "alice@example.com"}
""".data(using: .utf8)!

let user = try JSONDecoder().decode(User.self, from: json)
let encoded = try JSONEncoder().encode(user)
```

---

## User Interface

### SwiftUI & UIKit

| Framework | Type | Recommended | iOS | Notes |
|-----------|------|-------------|-----|-------|
| **SwiftUI** | Declarative | ✅ New projects | 13.0+ | Modern, reactive, cross-platform |
| **UIKit** | Imperative | ✅ Legacy/Complex | 2.0+ | Mature, powerful, more control |
| **AppKit** | Desktop | ✅ macOS | 10.0+ | Desktop application framework |

### SwiftUI Example

```swift
import SwiftUI

struct ContentView: View {
    @State private var name = ""
    @State private var isPresented = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Enter name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: { isPresented.toggle() }) {
                    Text("Show Details")
                }
                
                NavigationLink("Go to Detail", destination: DetailView())
            }
            .navigationTitle("Main")
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("Detail content")
    }
}
```

### UIKit Equivalent

```swift
import UIKit

class ViewController: UIViewController {
    let textField = UITextField()
    let button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.placeholder = "Enter name"
        textField.borderStyle = .roundedRect
        
        button.setTitle("Show Details", for: .normal)
        button.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        
        view.addSubview(textField)
        view.addSubview(button)
    }
    
    @objc func showDetails() {
        // Navigation logic
    }
}
```

### Layout Frameworks

| Framework | Purpose | Style |
|-----------|---------|-------|
| **SwiftUI Layouts** | View composition | Declarative |
| **Auto Layout** | Responsive design | Declarative (constraints) |
| **UIStackView** | Linear layouts | Imperative |

---

## Networking & Data

### Network Communication

| Framework | Purpose | Use Case |
|-----------|---------|----------|
| **URLSession** | HTTP networking | REST APIs, downloads, uploads |
| **Network** | Low-level networking | Raw sockets, custom protocols |
| **Bonjour** | Local network discovery | Device discovery, local services |
| **WebKit** | Web browsing | In-app web content |

### URLSession Example

```swift
import Foundation

class APIClient {
    func fetchUsers() async throws -> [User] {
        let url = URL(string: "https://api.example.com/users")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    func createUser(_ user: User) async throws -> User {
        let url = URL(string: "https://api.example.com/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(user)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw APIError.creationFailed
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case creationFailed
}
```

### Data Persistence

| Framework | Purpose | Use Case |
|-----------|---------|----------|
| **UserDefaults** | Simple key-value | App settings, user preferences |
| **Core Data** | Object relational | Complex data models, relationships |
| **SQLite** | SQL database | Raw SQL queries, advanced features |
| **CloudKit** | Cloud sync | iCloud synchronization |
| **FileManager** | File I/O | Documents, caches |

### Core Data Example

```swift
import CoreData

class DataManager {
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
    }
    
    func fetchUsers() -> [User] {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let context = container.viewContext
        return (try? context.fetch(request)) ?? []
    }
    
    func saveUser(name: String, email: String) {
        let context = container.viewContext
        let user = UserEntity(context: context)
        user.name = name
        user.email = email
        
        try? context.save()
    }
}
```

---

## Media & Graphics

### Audio & Video

| Framework | Purpose | iOS |
|-----------|---------|-----|
| **AVFoundation** | Audio/video playback & recording | 4.0+ |
| **MediaPlayer** | Media playback controls | 2.0+ |
| **SoundAnalysis** | Audio analysis | 12.0+ |

### Graphics & Animation

| Framework | Purpose | iOS |
|-----------|---------|-----|
| **Metal** | GPU rendering, games | 8.0+ |
| **SceneKit** | 3D graphics | 8.0+ |
| **SpriteKit** | 2D graphics, games | 7.0+ |
| **Core Graphics** | 2D drawing | 2.0+ |
| **Core Animation** | Animations | 2.0+ |

### AVPlayer Example

```swift
import AVKit

class VideoPlayerViewController: UIViewController {
    func playVideo() {
        guard let url = URL(string: "https://example.com/video.mp4") else {
            return
        }
        
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true) {
            player.play()
        }
    }
}

// SwiftUI equivalent
import SwiftUI

struct VideoPlayerView: View {
    let url: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .aspectRatio(16/9, contentMode: .fit)
    }
}
```

---

## Machine Learning & AI

### Core ML & Vision

| Framework | Purpose | iOS |
|-----------|---------|-----|
| **Core ML** | Machine learning models | 11.0+ |
| **Vision** | Image analysis, object detection | 11.0+ |
| **Natural Language** | Text processing, sentiment | 12.0+ |
| **Speech** | Speech recognition | 10.0+ |

### Vision Example

```swift
import Vision

class ImageAnalyzer {
    func detectObjects(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNCoreMLRequest(
            model: try! VNCoreMLModel(for: MobileNetV2().model)
        ) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }
            
            for result in results.prefix(3) {
                print("\(result.identifier): \(result.confidence)")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
    
    func detectFaces(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation] else {
                return
            }
            
            for observation in observations {
                print("Face detected: \(observation.boundingBox)")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
}
```

### Natural Language Processing

```swift
import NaturalLanguage

class TextAnalyzer {
    func analyzeSentiment(_ text: String) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let sentiment = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        
        print("Sentiment: \(sentiment?.rawValue ?? "unknown")")
    }
    
    func extractEntities(_ text: String) {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, range in
            if let tag = tag {
                let entity = String(text[range])
                print("\(tag.rawValue): \(entity)")
            }
            return true
        }
    }
}
```

---

## System Services

### Device Information & Hardware

| Framework | Purpose | iOS |
|-----------|---------|-----|
| **UIDevice** | Device properties | 2.0+ |
| **Core Location** | GPS, geofencing | 2.0+ |
| **CoreMotion** | Accelerometer, gyroscope | 4.0+ |
| **CoreBluetooth** | Bluetooth connectivity | 5.0+ |
| **HealthKit** | Health & fitness data | 8.0+ |

### Core Location Example

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let location = locations.last {
            print("Latitude: \(location.coordinate.latitude)")
            print("Longitude: \(location.coordinate.longitude)")
        }
    }
}
```

### Permissions (Privacy)

| Permission | Framework | Requires |
|-----------|-----------|----------|
| Location | Core Location | `NSLocationWhenInUseUsageDescription` |
| Camera | AVFoundation | `NSCameraUsageDescription` |
| Microphone | AVFoundation | `NSMicrophoneUsageDescription` |
| Photos | Photos | `NSPhotoLibraryUsageDescription` |
| Health | HealthKit | `NSHealthShareUsageDescription` |
| Bluetooth | CoreBluetooth | `NSBluetoothPeripheralUsageDescription` |

---

## Testing & Development

### Testing Frameworks

| Framework | Purpose | iOS |
|-----------|---------|-----|
| **XCTest** | Unit/UI testing | 5.0+ |
| **XCUITest** | UI automation | 9.0+ |
| **Quick** | BDD-style testing | Third-party |
| **Nimble** | Matcher assertions | Third-party |

### XCTest Example

```swift
import XCTest

class UserTests: XCTestCase {
    var sut: UserManager!
    
    override func setUp() {
        super.setUp()
        sut = UserManager()
    }
    
    func testCreateUser() {
        // Arrange
        let name = "Alice"
        let email = "alice@example.com"
        
        // Act
        let user = sut.createUser(name: name, email: email)
        
        // Assert
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.email, email)
    }
    
    func testFetchUsers() async throws {
        // Arrange
        let expectedCount = 2
        
        // Act
        let users = try await sut.fetchUsers()
        
        // Assert
        XCTAssertEqual(users.count, expectedCount)
    }
}

class UserUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        app.launch()
    }
    
    func testUserListDisplay() {
        // Tap button
        app.buttons["Show Users"].tap()
        
        // Verify UI element exists
        XCTAssertTrue(app.tables["UserTable"].exists)
        
        // Check cell count
        let cells = app.tables["UserTable"].cells
        XCTAssertGreaterThan(cells.count, 0)
    }
}
```

### Debugging Tools

| Tool | Purpose |
|------|---------|
| **Xcode Debugger** | Breakpoints, step through code |
| **Instruments** | Performance profiling |
| **Console** | Logging and LLDB commands |
| **Network Link Conditioner** | Network simulation |
| **Simulator** | Device emulation |

---

## Quick Reference

### Common Imports

```swift
// UI Development
import SwiftUI
import UIKit

// Networking & Data
import Foundation
import Combine
import CloudKit

// Media
import AVFoundation
import MediaPlayer

// Machine Learning
import CoreML
import Vision
import NaturalLanguage

// System Services
import CoreLocation
import CoreMotion
import HealthKit
import CoreBluetooth

// Testing
import XCTest
```

### Framework Dependencies

```
SwiftUI → Foundation, Combine
UIKit → Foundation, CoreGraphics
AVFoundation → Foundation, Media
Core Data → Foundation
Combine → Foundation
Network → Foundation
CloudKit → Foundation
```

---

## 🔗 Related Topics

- [**03-networking-backend/backend.md**](../03-networking-backend/backend.md) - API design and networking
- [**06-data/core-data.md**](../06-data/core-data.md) - Core Data fundamentals
- [**07-advanced/vision-and-machine-learning.md**](../07-advanced/vision-and-machine-learning.md) - Advanced ML/Vision
- [**07-advanced/logging-and-monitoring.md**](../07-advanced/logging-and-monitoring.md) - Debugging and profiling
- [**04-app-lifecycle/xcode-and-ide.md**](../04-app-lifecycle/xcode-and-ide.md) - Development tools
