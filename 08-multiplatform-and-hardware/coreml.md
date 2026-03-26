# CoreML - Machine Learning in iOS

## Overview

CoreML enables on-device machine learning by running trained models locally. Models are optimized for performance and privacy.

## Main Topics

- [Model Loading](#model-loading)
- [Basic Predictions](#basic-predictions)
- [Image Classification](#image-classification)
- [Model Conversion](#model-conversion)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [CoreML](https://developer.apple.com/documentation/coreml)

---

## Model Loading

### Loading Models

```swift
import CoreML

class MLModelManager {
    static let shared = MLModelManager()
    
    func loadModel(named modelName: String) throws -> MLModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw MLError.modelNotFound
        }
        
        let model = try MLModel(contentsOf: modelURL)
        return model
    }
    
    func loadModelWithConfiguration(named modelName: String) throws -> MLModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw MLError.modelNotFound
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        let model = try MLModel(contentsOf: modelURL, configuration: config)
        return model
    }
}

enum MLError: Error {
    case modelNotFound
    case predictionFailed
    case invalidInput
}
```

---

## Basic Predictions

### Simple Classification

```swift
import CoreML

class SimpleClassifier {
    var model: SampleClassifier?
    
    func setup() throws {
        guard let modelURL = Bundle.main.url(forResource: "SampleClassifier", withExtension: "mlmodelc") else {
            throw MLError.modelNotFound
        }
        
        self.model = try SampleClassifier(contentsOf: modelURL)
    }
    
    func classify(_ input: [Double]) throws -> String {
        guard let model = model else {
            throw MLError.modelNotFound
        }
        
        do {
            let prediction = try model.prediction(input: input)
            return prediction.classLabel
        } catch {
            throw MLError.predictionFailed
        }
    }
}
```

### Multi-Input Predictions

```swift
import CoreML

class MultiInputPredictor {
    var model: MLModel?
    
    func setup(modelName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw MLError.modelNotFound
        }
        
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func predict(features: [String: MLFeatureValue]) throws -> MLFeatureProvider {
        guard let model = model else {
            throw MLError.modelNotFound
        }
        
        let input = try MLDictionaryFeatureProvider(dictionary: features)
        let output = try model.prediction(from: input)
        
        return output
    }
    
    func predictWithMultipleInputs(values: [String: Double]) throws -> [String: Any] {
        var features: [String: MLFeatureValue] = [:]
        
        for (key, value) in values {
            features[key] = MLFeatureValue(double: value)
        }
        
        let output = try predict(features: features)
        var result: [String: Any] = [:]
        
        for featureName in output.featureNames {
            result[featureName] = output.featureValue(for: featureName)?.doubleValue
        }
        
        return result
    }
}
```

---

## Image Classification

### Classifying Images

```swift
import CoreML
import Vision

class ImageClassifier {
    var model: VNCoreMLModel?
    
    func setup(modelName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw MLError.modelNotFound
        }
        
        guard let mlModel = try? MLModel(contentsOf: modelURL) else {
            throw MLError.modelNotFound
        }
        
        self.model = try VNCoreMLModel(for: mlModel)
    }
    
    func classify(image: UIImage, completion: @escaping (String?, Error?) -> Void) {
        guard let model = model, let buffer = image.toCVPixelBuffer() else {
            completion(nil, MLError.invalidInput)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(nil, MLError.predictionFailed)
                return
            }
            
            completion(topResult.identifier, nil)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        try? handler.perform([request])
    }
    
    func classifyAsync(image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            classify(image: image) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, .readAndWrite)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readAndWrite) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.draw(self.cgImage!, in: CGRect(origin: .zero, size: self.size))
        return buffer
    }
}
```

---

## Model Conversion

### Using Create ML Models

```swift
import CoreML

class ModelConverter {
    static func convertAndTest(modelPath: String) throws {
        let url = URL(fileURLWithPath: modelPath)
        
        // Load compiled model
        let model = try MLModel(contentsOf: url)
        
        // Get model information
        print("Model: \(model.modelDescription.metadata)")
        print("Input features: \(model.modelDescription.inputDescriptionsByName)")
        print("Output features: \(model.modelDescription.outputDescriptionsByName)")
    }
}
```

---

## 🎯 Best Practices

### 1. Use on-device Processing
```swift
// ✅ Process locally for privacy
let prediction = try model.prediction(from: input)

// ❌ Send raw data to server
send(imageData)  // Privacy risk
```

### 2. Optimize Model Size
```swift
// ✅ Use quantized models
let config = MLModelConfiguration()
config.computeUnits = .cpuAndNeuralEngine

// ❌ Use full precision (slower)
```

### 3. Cache Model Reference
```swift
// ✅ Load once, reuse
let classifier = ImageClassifier()
try? classifier.setup(modelName: "Model")

// Then use multiple times

// ❌ Reload model each time
for image in images {
    try MLModel(contentsOf: url)  // Slow
}
```

---

## ❌ Common Mistakes

### Mistake 1: Not Handling Model Absence

**WRONG:**
```swift
// ❌ Force unwrap
let model = try! MLModel(contentsOf: url)
```

**CORRECT:**
```swift
// ✅ Proper error handling
let model = try MLModel(contentsOf: url)
```

---

### Mistake 2: Processing on Main Thread

**WRONG:**
```swift
// ❌ Blocks UI
let prediction = try model.prediction(from: input)
updateUI()
```

**CORRECT:**
```swift
// ✅ Use background thread
DispatchQueue.global().async {
    let prediction = try? model.prediction(from: input)
    DispatchQueue.main.async {
        self.updateUI()
    }
}
```

---

## Related Topics

- [Vision Framework](.)
- [Async/Await](../02-concurrency/async-await.md)
- [GCD and Dispatch](../07-advanced/gcd-and-dispatch.md)

---

**Bring machine learning to your app!**
