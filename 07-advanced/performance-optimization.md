# Performance Optimization - Speed, Memory, and Battery

## Overview

Performance optimization ensures apps run smoothly, use memory efficiently, and preserve battery life. Key areas include rendering, memory management, and algorithmic efficiency.

## Main Topics

- [Performance Metrics](#performance-metrics)
- [Rendering Performance](#rendering-performance)
- [Memory Optimization](#memory-optimization)
- [Algorithmic Efficiency](#algorithmic-efficiency)
- [Battery Optimization](#battery-optimization)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Performance Best Practices](https://developer.apple.com/documentation/os/seeing_improved_performance)

---

## Performance Metrics

### Key Metrics to Monitor

```swift
// Frame Rate (Frames Per Second)
// - 60 FPS: Smooth (standard)
// - 120 FPS: Very smooth (ProMotion displays)
// - <30 FPS: Noticeable stuttering

// Memory Usage
// - App memory limit: 1-4GB depending on device
// - Private: Data only app uses
// - Shared: System framework memory

// CPU Usage
// - Percentage of CPU core used
// - Affects battery drain

// Battery Impact
// - Foreground: ~1 hour = 1% battery
// - Background task: Minimize significantly
```

### Using Xcode Instruments

```swift
// Profile with Xcode Instruments:
// 1. Product → Profile (Cmd+I)
// 2. Select instrument:
//    - Core Animation: Frame rate, rendering
//    - Allocations: Memory usage
//    - Leaks: Memory leaks
//    - Energy Impact: Battery drain
//    - System Trace: All metrics
```

---

## Rendering Performance

### Measuring Frame Rate

```swift
import UIKit

class FrameRateMeasurer {
    var displayLink: CADisplayLink?
    var frameCount = 0
    var lastTimestamp: CFTimeInterval = 0
    
    func startMeasuring() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(tick)
        )
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc func tick(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        
        let elapsed = displayLink.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            print("FPS: \(fps)")
            
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
    
    func stopMeasuring() {
        displayLink?.invalidate()
    }
}
```

### Optimizing UITableView

```swift
import UIKit

// ❌ Slow - Complex cell rendering
class SlowTableCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Heavy layout calculations
        for _ in 0..<100 {
            let view = UIView()
            contentView.addSubview(view)
        }
    }
}

// ✅ Fast - Efficient cell rendering
class FastTableCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with item: Item) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        
        // Load image asynchronously
        loadImage(item.imageURL)
    }
    
    private func loadImage(_ url: URL) {
        Task {
            if let image = try await ImageCache.shared.image(for: url) {
                thumbnailImage.image = image
            }
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set row height to fixed value (avoid re-estimation)
        tableView.rowHeight = 80
        
        // Reduce separator drawing
        tableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure cell
        // Avoid heavy operations here
        
        return cell
    }
}
```

### Optimizing View Rasterization

```swift
import UIKit

class OptimizedView: UIView {
    func optimizeHeavyView() {
        // Rasterize complex view hierarchy
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        // Do this only for static views
        // Not for animated views (defeats animation optimization)
    }
    
    func animateOptimizedView() {
        // Stop rasterization before animation
        layer.shouldRasterize = false
        
        // Animate
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0.5
        }
        
        // Re-rasterize after animation
        layer.shouldRasterize = true
    }
}
```

---

## Memory Optimization

### Detecting Memory Leaks

```swift
// ❌ Leak: Retain cycle
class ViewController: UIViewController {
    var completion: (() -> Void)?
    
    func setupCallback() {
        completion = {
            self.updateUI()  // Strong reference to self
        }
    }
}

// ✅ Fix: Weak reference
class ViewController: UIViewController {
    var completion: (() -> Void)?
    
    func setupCallback() {
        completion = { [weak self] in
            self?.updateUI()
        }
    }
}
```

### Image Optimization

```swift
import UIKit

class ImageOptimizer {
    // ❌ Loads full resolution
    func loadFullResolutionImage(_ url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    // ✅ Resize to screen size
    func loadOptimizedImage(_ url: URL, for size: CGSize) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        
        return image.resized(to: size)
    }
    
    // ✅ Cache loaded images
    let imageCache = NSCache<NSString, UIImage>()
    
    func loadCachedImage(_ url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        if let cached = imageCache.object(forKey: key) {
            return cached
        }
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        
        imageCache.setObject(image, forKey: key)
        return image
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
```

### Memory Warnings

```swift
import UIKit

class MemoryAwareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc func didReceiveMemoryWarning() {
        print("Memory warning received")
        
        // Clear caches
        clearImageCache()
        clearDataCache()
    }
    
    func clearImageCache() {
        NSURLCache.shared.removeAllCachedResponses()
    }
    
    func clearDataCache() {
        // Clear your custom caches
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

## Algorithmic Efficiency

### Sorting Optimization

```swift
import Foundation

// ❌ Bubble sort: O(n²)
func bubbleSort(_ array: [Int]) -> [Int] {
    var arr = array
    for i in 0..<arr.count {
        for j in 0..<arr.count - i - 1 {
            if arr[j] > arr[j + 1] {
                arr.swapAt(j, j + 1)
            }
        }
    }
    return arr
}

// ✅ Quicksort: O(n log n)
func quickSort(_ array: [Int]) -> [Int] {
    guard array.count > 1 else { return array }
    
    let pivot = array[array.count / 2]
    let less = array.filter { $0 < pivot }
    let equal = array.filter { $0 == pivot }
    let greater = array.filter { $0 > pivot }
    
    return quickSort(less) + equal + quickSort(greater)
}

// ✅ Built-in (optimized)
let sorted = array.sorted()
```

### Search Optimization

```swift
// ❌ Linear search: O(n)
func linearSearch(_ array: [Int], target: Int) -> Int? {
    for (index, value) in array.enumerated() {
        if value == target {
            return index
        }
    }
    return nil
}

// ✅ Binary search: O(log n) - requires sorted array
func binarySearch(_ array: [Int], target: Int) -> Int? {
    var left = 0
    var right = array.count - 1
    
    while left <= right {
        let mid = (left + right) / 2
        
        if array[mid] == target {
            return mid
        } else if array[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }
    return nil
}
```

---

## Battery Optimization

### Location Monitoring

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    func startLocationTracking() {
        manager.delegate = self
        
        // ❌ High battery drain
        // manager.desiredAccuracy = kCLLocationAccuracyBest
        // manager.distanceFilter = kCLDistanceFilterNone
        
        // ✅ Battery friendly
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100  // Only update every 100 meters
        manager.pausesLocationUpdatesAutomatically = true
        
        manager.startUpdatingLocation()
    }
}
```

### Background Task Optimization

```swift
import UIKit

class BackgroundTaskManager {
    func performBackgroundWork() {
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Perform work
        DispatchQueue.global().async {
            self?.doWork()
            
            // Always end task
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
    }
    
    func doWork() {
        // Minimize battery drain
        // Batch operations
        // Avoid high CPU usage
    }
}
```

---

## 🎯 Best Practices

### 1. Profile Before Optimizing
```swift
// ✅ Use instruments to identify bottlenecks
// Profile → Core Animation / Allocations / etc

// ❌ Optimize blindly
// May not fix actual problems
```

### 2. Cache Appropriately
```swift
// ✅ Cache expensive operations
let imageCache = NSCache<NSString, UIImage>()

// ❌ Cache everything
NSCache.unlimited  // Wastes memory
```

### 3. Use Correct Data Structures
```swift
// ✅ Array for sequential access
// ✅ Set for membership testing
// ✅ Dictionary for key-value lookup

// ❌ Array for all use cases
// O(n) lookup instead of O(1)
```

---

## ❌ Common Mistakes

### Mistake 1: Not Measuring

**WRONG:**
```swift
// ❌ Guess at performance
// "This looks slow, let me optimize"
```

**CORRECT:**
```swift
// ✅ Profile and measure
// Use Instruments
// Identify real bottleneck
```

---

### Mistake 2: Premature Optimization

**WRONG:**
```swift
// ❌ Optimize before profiling
// Complex micro-optimizations in wrong places
```

**CORRECT:**
```swift
// ✅ Optimize hot paths
// Profile first
// Focus on biggest gains
```

---

### Mistake 3: Memory Leak Cycles

**WRONG:**
```swift
// ❌ Retain cycle
imageView.onTap = {
    self.loadNextImage()  // Strong self
}
```

**CORRECT:**
```swift
// ✅ Weak reference
imageView.onTap = { [weak self] in
    self?.loadNextImage()
}
```

---

## Related Topics

- [Memory Management](../07-advanced/memory-management.md)
- [GCD and Dispatch](../07-advanced/gcd-and-dispatch.md)
- [Algorithms](algorithms.md)

---

**Master performance optimization for smooth, efficient apps!**
