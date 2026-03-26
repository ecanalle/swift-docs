# ARKit - Augmented Reality

## Overview

ARKit enables augmented reality experiences with real-time camera tracking, spatial understanding, and 3D object placement.

## Main Topics

- [Basic AR Session](#basic-ar-session)
- [Plane Detection](#plane-detection)
- [3D Object Placement](#3d-object-placement)
- [Face Tracking](#face-tracking)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [ARKit](https://developer.apple.com/documentation/arkit)

---

## Basic AR Session

### Setting Up AR View

```swift
import ARKit
import RealityKit

class ARViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

class ARViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    let arSession = ARSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        setupARSession()
    }
    
    private func setupARSession() {
        arSession.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR not supported on this device")
            return
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arSession.run(configuration)
        arView.session = arSession
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session error: \(error)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSession.pause()
    }
}
```

---

## Plane Detection

### Detecting Surfaces

```swift
import ARKit
import RealityKit

class PlaneDetectionViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    let arSession = ARSession()
    var planeAnchors: [PlaneAnchor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        setupPlaneDetection()
        addGestureRecognizers()
    }
    
    private func setupPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        arSession.run(configuration)
        arView.session = arSession
    }
    
    private func addGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
            let anchor = try? Experience.loadBox(for: result.anchor)
            
            if let anchor = anchor {
                arView.scene.addAnchor(anchor)
            }
        }
    }
}
```

---

## 3D Object Placement

### Placing Custom Objects

```swift
import ARKit
import RealityKit

class ObjectPlacementViewController: UIViewController {
    var arView: ARView!
    let arSession = ARSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        setupAR()
        addPlacementGestures()
    }
    
    private func setupAR() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        arSession.run(configuration)
        arView.session = arSession
    }
    
    private func addPlacementGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(placeObject))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc func placeObject(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first else {
            return
        }
        
        // Create anchor at tap location
        var anchor = AnchorEntity(plane: .horizontal, classification: .floor)
        
        // Add 3D model
        addModelToAnchor(&anchor)
        
        arView.scene.addAnchor(anchor)
    }
    
    private func addModelToAnchor(_ anchor: inout AnchorEntity) {
        // Load USDZ model
        var model = ModelEntity(model: "model.usdz")
        model.position = [0, 0.1, 0]
        model.scale = [0.5, 0.5, 0.5]
        
        anchor.addChild(model)
    }
}
```

---

## Face Tracking

### Detecting and Tracking Faces

```swift
import ARKit
import RealityKit

class FaceTrackingViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    let arSession = ARSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        setupFaceTracking()
    }
    
    private func setupFaceTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking not supported")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        arSession.delegate = self
        arSession.run(configuration)
        arView.session = arSession
    }
    
    func session(_ session: ARSession, didUpdate anchors: [AnchorUpdate]) {
        for update in anchors {
            switch update {
            case .added(let anchor):
                if let faceAnchor = anchor as? FaceAnchor {
                    handleFaceDetected(faceAnchor)
                }
                
            case .updated(let anchor):
                if let faceAnchor = anchor as? FaceAnchor {
                    updateFaceTracking(faceAnchor)
                }
                
            case .removed:
                print("Face removed")
            }
        }
    }
    
    private func handleFaceDetected(_ anchor: FaceAnchor) {
        print("Face detected")
        print("Blend shapes: \(anchor.blendShapes)")
    }
    
    private func updateFaceTracking(_ anchor: FaceAnchor) {
        // Access facial expressions
        if let smileFactor = anchor.blendShapes[.mouthSmile] {
            print("Smile: \(smileFactor)")
        }
        
        if let eyeWink = anchor.blendShapes[.eyeWinkLeft] {
            print("Left eye wink: \(eyeWink)")
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Check AR Availability
```swift
// ✅ Check before running AR
guard ARWorldTrackingConfiguration.isSupported else {
    showUnsupportedMessage()
    return
}

// ❌ Assume AR is available
let config = ARWorldTrackingConfiguration()
```

### 2. Pause AR Session
```swift
// ✅ Pause when not needed
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    arSession.pause()
}

// ❌ Let session run in background
// Drains battery
```

### 3. Handle Permission
```swift
// ✅ Request camera permission first
AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted {
        self.setupAR()
    }
}

// ❌ Assume camera permission
```

---

## ❌ Common Mistakes

### Mistake 1: Not Checking Device Support

**WRONG:**
```swift
// ❌ Crashes on unsupported devices
let config = ARWorldTrackingConfiguration()
arSession.run(config)
```

**CORRECT:**
```swift
// ✅ Check first
guard ARWorldTrackingConfiguration.isSupported else {
    print("AR not supported")
    return
}
let config = ARWorldTrackingConfiguration()
arSession.run(config)
```

---

### Mistake 2: Not Requesting Camera Permission

**WRONG:**
```swift
// ❌ Camera access denied silently
arSession.run(configuration)
```

**CORRECT:**
```swift
// ✅ Request permission
AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted {
        DispatchQueue.main.async {
            self.arSession.run(configuration)
        }
    }
}
```

---

## Related Topics

- [CoreML - ML Models](coreml.md)
- [Camera and Photos](camera-and-photos.md)
- [Vision Framework](.)

---

**Create immersive AR experiences!**
