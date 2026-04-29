# Vision Framework & Machine Learning - Advanced Image Analysis 🎯

## Overview
The Vision framework combined with Core ML enables powerful image recognition, object detection, and real-time visual analysis. Build intelligent apps that understand images like humans do—from identifying objects to recognizing text and detecting faces.

## Main Topics
- [Vision Framework Fundamentals](#vision-framework-fundamentals) - Core image analysis
- [Object Detection and Recognition](#object-detection-and-recognition) - Detecting what's in images
- [Face Detection and Recognition](#face-detection-and-recognition) - Facial analysis
- [Text Recognition (OCR)](#text-recognition-ocr) - Extracting text from images
- [Core ML Integration](#core-ml-integration) - Using trained models
- [Real-Time Processing](#real-time-processing) - Live camera analysis
- [Best Practices](#-best-practices) - Optimization strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - Avoiding pitfalls

## Official Documentation
- [Apple: Vision Framework](https://developer.apple.com/documentation/vision)
- [Apple: Core ML](https://developer.apple.com/documentation/coreml)
- [Apple: Create ML](https://developer.apple.com/documentation/createml)
- [WWDC 2019: Vision Framework Deep Dive](https://developer.apple.com/videos/play/wwdc2019/222)

---

## Vision Framework Fundamentals

### Basic Image Analysis Setup

The Vision framework processes images through requests and handlers. Each request type performs a specific analysis task.

```swift
// ✅ Correct: Setting up basic Vision request
import Vision
import CoreImage

class ImageAnalyzer {
    func analyzeImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        // Create request
        let request = VNDetectFacesRequest { request, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            // Process results
            guard let observations = request.results as? [VNFaceObservation] else { return }
            print("Found \(observations.count) faces")
        }
        
        // Configure request
        request.revision = VNDetectFacesRequestRevision3
        
        // Execute request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Error performing request: \(error.localizedDescription)")
        }
    }
}

// Usage
let analyzer = ImageAnalyzer()
if let image = UIImage(named: "photo") {
    analyzer.analyzeImage(image)
}
```

**Key Points:**
- Requests are reusable—create once, configure, and execute multiple times
- Use `revision` parameter to specify algorithm version
- Results are delivered in handler's completion callback

---

## Object Detection and Recognition

### Using Pre-trained Core ML Models

```swift
// ✅ Correct: Object detection with Core ML
import Vision
import CoreML

class ObjectDetector {
    let model: VNCoreMLModel
    
    init() throws {
        let mlModel = try YOLOv3(configuration: MLModelConfiguration()).model
        self.model = try VNCoreMLModel(for: mlModel)
    }
    
    func detectObjects(in image: UIImage, completion: @escaping ([VNRecognizedObjectObservation]) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            // Filter by confidence threshold
            let filtered = results.filter { $0.confidence > 0.5 }
            completion(filtered)
        }
        
        // Process on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Detection error: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}

// Usage
let detector = try ObjectDetector()
detector.detectObjects(in: cameraFrame) { objects in
    DispatchQueue.main.async {
        for object in objects {
            print("\(object.identifier): \(String(format: "%.2f", object.confidence))")
            print("  Bounds: \(object.boundingBox)")
        }
    }
}
```

### Rectangle and Barcode Detection

```swift
// ✅ Correct: Detecting rectangles and QR codes
import Vision

func detectRectanglesAndCodes(in image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    
    // Detect rectangles
    let rectangleRequest = VNDetectRectanglesRequest { request, error in
        guard let rectangles = request.results as? [VNRectangleObservation] else { return }
        print("Detected \(rectangles.count) rectangles")
        
        for rectangle in rectangles {
            print("Confidence: \(rectangle.confidence)")
            print("Top-left: \(rectangle.topLeft)")
            print("Top-right: \(rectangle.topRight)")
        }
    }
    
    // Detect barcodes and QR codes
    let barcodeRequest = VNDetectBarcodesRequest { request, error in
        guard let barcodes = request.results as? [VNBarcodeObservation] else { return }
        
        for barcode in barcodes {
            print("Barcode type: \(barcode.symbology)")
            print("Payload: \(barcode.payloadStringValue ?? "N/A")")
        }
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    do {
        try handler.perform([rectangleRequest, barcodeRequest])
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

---

## Face Detection and Recognition

### Face Detection and Analysis

```swift
// ✅ Correct: Detecting faces and extracting features
import Vision

class FaceAnalyzer {
    func analyzeFaces(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            
            for face in faces {
                print("Face detected:")
                print("  Confidence: \(face.confidence)")
                print("  Bounds: \(face.boundingBox)")
                
                // Access face landmarks if available
                if #available(iOS 13, *) {
                    let landmarkRequest = VNDetectFaceLandmarksRequest { landmarkRequest, _ in
                        guard let landmarks = landmarkRequest.results as? [VNFaceObservation] else { return }
                        
                        for landmark in landmarks {
                            if let nose = landmark.landmarks?.nose {
                                print("  Nose points: \(nose.pointCount)")
                            }
                            if let mouth = landmark.landmarks?.mouth {
                                print("  Mouth points: \(mouth.pointCount)")
                            }
                            if let eyes = landmark.landmarks?.allPoints {
                                print("  Total landmarks: \(eyes.pointCount)")
                            }
                        }
                    }
                    
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? handler.perform([landmarkRequest])
                }
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

// Usage
let analyzer = FaceAnalyzer()
if let image = UIImage(named: "group_photo") {
    analyzer.analyzeFaces(in: image)
}
```

### Face Quality Assessment

```swift
// ✅ Correct: Evaluating face quality for recognition
import Vision

func assessFaceQuality(_ image: UIImage, completion: @escaping (Double) -> Void) {
    guard let cgImage = image.cgImage else { return }
    
    let request = VNDetectFaceQualityRequest { request, error in
        guard let faces = request.results as? [VNFaceObservation] else {
            completion(0)
            return
        }
        
        // Average quality across all faces
        let avgQuality = faces.map { $0.faceCaptureQuality ?? 0 }.reduce(0, +) / Double(faces.count)
        completion(avgQuality)
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Quality assessment error: \(error.localizedDescription)")
            completion(0)
        }
    }
}

// Usage
assessFaceQuality(capturedImage) { quality in
    if quality > 0.7 {
        print("Face quality is good: \(String(format: "%.2f", quality))")
    } else {
        print("Face quality is poor, please adjust camera")
    }
}
```

---

## Text Recognition (OCR)

### Extracting Text from Images

```swift
// ✅ Correct: Optical Character Recognition
import Vision

class TextRecognizer {
    func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                completion("")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            completion(fullText)
        }
        
        // Enable fast language processing
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Error: \(error.localizedDescription)")
                completion("")
            }
        }
    }
}

// Usage
let recognizer = TextRecognizer()
recognizer.recognizeText(in: documentImage) { text in
    DispatchQueue.main.async {
        print("Extracted text:\n\(text)")
    }
}
```

---

## Core ML Integration

### Custom Vision Models

```swift
// ✅ Correct: Using custom trained Core ML model
import Vision
import CoreML

class CustomClassifier {
    let model: VNCoreMLModel
    
    init(modelName: String) throws {
        // Load your custom Create ML model
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw NSError(domain: "Model not found", code: -1)
        }
        
        let mlModel = try MLModel(contentsOf: modelURL)
        self.model = try VNCoreMLModel(for: mlModel)
    }
    
    func classify(_ image: UIImage, completion: @escaping ([(label: String, confidence: Double)]) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                completion([])
                return
            }
            
            let classifications = results.map { observation in
                (label: observation.identifier, confidence: Double(observation.confidence))
            }
            
            // Sort by confidence
            let sorted = classifications.sorted { $0.confidence > $1.confidence }
            completion(sorted)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Classification error: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}

// Usage
let classifier = try CustomClassifier(modelName: "PlantIdentifier")
classifier.classify(plantPhoto) { results in
    DispatchQueue.main.async {
        for (label, confidence) in results.prefix(3) {
            print("\(label): \(String(format: "%.1f", confidence * 100))%")
        }
    }
}
```

---

## Real-Time Processing

### Live Camera Analysis

```swift
// ✅ Correct: Processing video frames in real-time
import Vision
import AVFoundation

class CameraAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let request = VNDetectFacesRequest()
    
    func startSession() throws {
        // Setup capture device
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        let input = try AVCaptureDeviceInput(device: camera)
        
        captureSession.addInput(input)
        
        // Setup video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        captureSession.addOutput(videoOutput)
        
        // Configure request for reuse
        request.revision = VNDetectFacesRequestRevision3
        
        // Start capturing
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, 
                       didDrop sampleBuffer: CMSampleBuffer, 
                       from connection: AVCaptureConnection) {}
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Skip frames for performance
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            
            DispatchQueue.main.async {
                guard let observations = self.request.results as? [VNFaceObservation] else { return }
                // Update UI with face positions
                for face in observations {
                    print("Face at: \(face.boundingBox)")
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
    }
}

// Usage
let analyzer = CameraAnalyzer()
try analyzer.startSession()
// ... later
analyzer.stopSession()
```

---

## ✅ Best Practices

### Practice 1: Batch Process on Background Thread
**DO:**
```swift
DispatchQueue.global(qos: .userInitiated).async {
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    
    DispatchQueue.main.async {
        self.updateUI()
    }
}
```

### Practice 2: Reuse Requests and Handlers
**DO:**
```swift
class ImageProcessor {
    private let request = VNDetectFacesRequest()
    
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
```

### Practice 3: Set Confidence Thresholds
**DO:**
```swift
let request = VNCoreMLRequest(model: model) { request, _ in
    guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
    let filtered = results.filter { $0.confidence > 0.7 }
    // Process filtered results
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Processing on Main Thread
**WRONG:**
```swift
// ❌ Blocks UI, causes lag
let request = VNDetectFacesRequest { _, _ in }
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])  // Blocks main thread
```

**CORRECT:**
```swift
// ✅ Background processing
DispatchQueue.global(qos: .userInitiated).async {
    let request = VNDetectFacesRequest { _, _ in }
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
}
```

### Mistake 2: Creating New Requests for Every Frame
**WRONG:**
```swift
// ❌ Inefficient memory usage
func processFrame(_ frame: CVPixelBuffer) {
    let request = VNDetectFacesRequest()  // Created every frame
    let handler = VNImageRequestHandler(cvPixelBuffer: frame, options: [:])
    try handler.perform([request])
}
```

**CORRECT:**
```swift
// ✅ Reuse request object
class FrameProcessor {
    let request = VNDetectFacesRequest()
    
    func processFrame(_ frame: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: frame, options: [:])
        try handler.perform([request])
    }
}
```

### Mistake 3: Not Specifying Language for Text Recognition
**WRONG:**
```swift
// ❌ Slower, less accurate without language hint
let request = VNRecognizeTextRequest { request, _ in }
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
```

**CORRECT:**
```swift
// ✅ Specify language for faster, more accurate recognition
let request = VNRecognizeTextRequest { request, _ in }
request.recognitionLanguages = ["en", "es"]
request.usesLanguageCorrection = true
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
```

### Mistake 4: Ignoring Result Confidence Scores
**WRONG:**
```swift
// ❌ Using all results without filtering
guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
for object in results {
    // Use all objects, including low-confidence ones
    print(object.identifier)
}
```

**CORRECT:**
```swift
// ✅ Filter by confidence threshold
guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
for object in results.filter({ $0.confidence > 0.7 }) {
    print(object.identifier)
}
```

---

## 🔗 Related Topics
- [Natural Language Processing](nlp-natural-language.md) - Text analysis
- [Core ML Models](../06-data/core-ml-models.md) - Machine learning
- [Camera and Photography](../05-features/camera-and-photography.md) - Camera integration
- [Real-Time Processing](async-concurrency.md) - Concurrent operations
- [Performance Optimization](performance-optimization.md) - Optimizing vision code
