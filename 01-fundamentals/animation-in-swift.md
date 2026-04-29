# Animation in Swift - Core Principles & Implementations

## Overview
Animations are fundamental to creating responsive, polished iOS applications. Swift provides multiple animation frameworks from basic UIView animations to SwiftUI's declarative animation system. Understanding timing, curves, and performance optimization is critical for building smooth user experiences.

## Main Topics
- [Animation Fundamentals](#animation-fundamentals)
- [UIView Animations](#uiview-animations)
- [SwiftUI Animations](#swiftui-animations)
- [CABasicAnimation](#cabasicanimation)
- [Animation Performance & Optimization](#animation-performance--optimization)
- [✅ Best Practices](#-best-practices)
- [❌ Common Mistakes](#-common-mistakes)

## Official Documentation
- [Apple: CABasicAnimation](https://developer.apple.com/documentation/quartzcore/cabasicanimation)
- [Apple: SwiftUI Animation](https://developer.apple.com/documentation/swiftui/animation)
- [Apple: UIView Animation](https://developer.apple.com/documentation/uikit/uiview#1656532)
- [WWDC 2022: What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10068/)

---

## Animation Fundamentals

### What Makes Good Animation

Animation should serve a purpose: providing feedback, guiding user attention, or conveying state changes. Every animation needs:
- **Duration**: How long the animation lasts (typically 0.2-0.5s for UI feedback)
- **Timing Curve**: How the animation progresses (ease-in, ease-out, linear)
- **Delay**: When animation starts (optional)
- **Repetition**: How many times it plays

**Key Principles:**
- Animations should feel natural and fluid
- Performance is critical—never drop frames
- Accessibility: Always provide non-animated alternatives
- Duration < 0.5s for UI feedback, < 2s for significant state changes

### Timing Curves Explained

```swift
// ❌ Linear (feels robotic)
UIView.animate(withDuration: 0.3, delay: 0, options: .linear, animations: {
    self.view.alpha = 0
})

// ✅ Ease-out (feels responsive, good for entrance)
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
    self.view.alpha = 0
})

// ✅ Ease-in (feels natural, good for exit)
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
    self.view.alpha = 0
})
```

---

## UIView Animations

### Basic Property Animations

UIView animations are perfect for animating standard properties like frame, alpha, background color, and transform. They're performant and easy to implement.

```swift
// ❌ No animation (instantaneous, jarring)
view.frame.origin.y = 100
view.alpha = 0.5

// ✅ Smooth animation with UIView
UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
    self.view.frame.origin.y = 100
    self.view.alpha = 0.5
})
```

### Chaining Animations

Sequence multiple animations using completion handlers:

```swift
// ✅ Chain animations with completion
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
    self.view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
}) { _ in
    UIView.animate(withDuration: 0.2, animations: {
        self.view.transform = CGAffineTransform.identity
    })
}
```

### Spring Animations

Spring animations feel natural and interactive, mimicking physical motion:

```swift
// ✅ Spring animation for bouncy effect
UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, 
               initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
    self.view.transform = CGAffineTransform(translationX: 0, y: 200)
})
```

---

## SwiftUI Animations

### Implicit Animations

SwiftUI's declarative model makes animations intuitive. Use `.animation()` modifier to animate state changes:

```swift
@State private var scale: CGFloat = 1.0

var body: some View {
    VStack {
        // ❌ State change without animation (jumps instantly)
        Circle()
            .scaleEffect(scale)
        
        Button("Tap Me") {
            scale = 2.0
        }
    }
}

// ✅ Add animation modifier
var body: some View {
    VStack {
        Circle()
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.3), value: scale)
        
        Button("Tap Me") {
            scale = 2.0
        }
    }
}
```

### Explicit Animations (withAnimation)

For complex state changes or animations affecting multiple views, use `withAnimation`:

```swift
@State private var isExpanded = false

var body: some View {
    VStack {
        if isExpanded {
            Text("Expanded content")
                .transition(.opacity)
        }
        
        Button("Toggle") {
            // ✅ Wrap state change in animation
            withAnimation(.easeInOut(duration: 0.5)) {
                isExpanded.toggle()
            }
        }
    }
}
```

### Custom Transitions

Create reusable, composable animations:

```swift
// ✅ Custom transition combining scale and opacity
struct ScaleAndFadeTransition: ViewModifier {
    var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1 : 0.1)
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// Usage
Text("Hello")
    .modifier(ScaleAndFadeTransition(isActive: isVisible))
```

---

## CABasicAnimation

### Core Animation for Complex Effects

When UIView or SwiftUI animations aren't sufficient, use Core Animation (CABasicAnimation) for frame-by-frame control:

```swift
// ❌ Wrong: Manual frame updates on main thread (jittery)
var timer: Timer?
var angle: CGFloat = 0

func startRotation() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
        self.angle += 5
        self.view.transform = CGAffineTransform(rotationAngle: self.angle * .pi / 180)
    }
}

// ✅ Correct: CABasicAnimation handles rendering
func startRotation() {
    let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
    rotation.toValue = CGFloat.pi * 2
    rotation.duration = 2.0
    rotation.repeatCount = .infinity
    rotation.timingFunction = CAMediaTimingFunction(name: .linear)
    
    view.layer.add(rotation, forKey: "rotation")
}
```

### Combining Multiple CAAnimations

Stack multiple animations on the same layer:

```swift
// ✅ Combine rotation + scale
let group = CAAnimationGroup()

let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
rotation.toValue = CGFloat.pi * 2

let scale = CABasicAnimation(keyPath: "transform.scale")
scale.toValue = 1.2

group.animations = [rotation, scale]
group.duration = 1.0
group.repeatCount = .infinity
group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

layer.add(group, forKey: "groupAnimation")
```

---

## Animation Performance & Optimization

### Rasterization for Complex Views

For heavily layered views, temporarily rasterize to a bitmap:

```swift
// ✅ Rasterize complex view hierarchy before animating
let complexView = createComplexViewHierarchy()

// Before animation
complexView.layer.shouldRasterize = true
complexView.layer.rasterizationScale = UIScreen.main.scale

UIView.animate(withDuration: 0.3, animations: {
    complexView.frame.origin.y = 200
}) { _ in
    // Disable rasterization after animation completes
    complexView.layer.shouldRasterize = false
}
```

### Profiling with Core Animation Tool

Always verify animations run at 60 FPS (iPhone standard):

```swift
// ✅ Test animation performance
import os

let logger = Logger()

CATransaction.begin()
CATransaction.setCompletionBlock {
    logger.log("Animation completed at 60 FPS")
}

let animation = CABasicAnimation(keyPath: "opacity")
animation.fromValue = 1.0
animation.toValue = 0.0
animation.duration = 1.0

layer.add(animation, forKey: nil)
CATransaction.commit()
```

### Avoiding Common Performance Pitfalls

```swift
// ❌ Don't: Update complex properties during animation
UIView.animate(withDuration: 0.5, animations: {
    self.view.frame = newFrame  // ✅ OK
    self.view.layer.shadow...   // ❌ Expensive during animation
    self.view.clipsToBounds = true  // ❌ Can cause issues
})

// ✅ Do: Update expensive properties before/after animation
view.layer.shadowColor = UIColor.black.cgColor
view.layer.shadowOpacity = 0.5
view.clipsToBounds = true

UIView.animate(withDuration: 0.5, animations: {
    self.view.frame = newFrame
})
```

---

## ✅ Best Practices

### 1. Keep Animations Short and Purposeful
**DO:**
```swift
// Quick, feedback-oriented animations (0.2-0.3s)
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
    button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
}) { _ in
    UIView.animate(withDuration: 0.2, animations: {
        button.transform = CGAffineTransform.identity
    })
}
```

### 2. Respect User Motion Accessibility Preferences
**DO:**
```swift
// ✅ Check for motion sensitivity and reduce animations
let motionManager = CMMotionManager()
if motionManager.isAccelerometerAvailable {
    // Scale animation duration based on accessibility preferences
    let duration = UIAccessibility.isReduceMotionEnabled ? 0.05 : 0.3
    UIView.animate(withDuration: duration, animations: {
        // Animation
    })
}
```

### 3. Test on Real Devices
Performance on simulator differs significantly from physical devices. Always profile on actual hardware.

### 4. Use Completion Handlers for Sequencing
**DO:**
```swift
// Chain animations properly
func animateSequence() {
    animate1 { 
        self.animate2 { 
            self.animate3 { }
        }
    }
}
```

### 5. Provide Visual Feedback Immediately
Animations should feel responsive, never delayed beyond 100ms.

---

## ❌ Common Mistakes

### Mistake 1: Hardcoded Duration Values

**WRONG:**
```swift
UIView.animate(withDuration: 0.5, animations: {
    self.view.alpha = 0
})
// ❌ Not optimized for accessibility
```

**CORRECT:**
```swift
// ✅ Adjust duration based on user preferences
let baseDuration = 0.5
let duration = UIAccessibility.isReduceMotionEnabled ? 0.05 : baseDuration

UIView.animate(withDuration: duration, animations: {
    self.view.alpha = 0
})
```

### Mistake 2: Animating Layer Properties Incorrectly

**WRONG:**
```swift
// ❌ Animating layer shadow directly (no effect)
UIView.animate(withDuration: 0.3, animations: {
    self.view.layer.shadowOpacity = 0.8
})
```

**CORRECT:**
```swift
// ✅ Use CABasicAnimation for layer properties
let shadowOpacity = CABasicAnimation(keyPath: "shadowOpacity")
shadowOpacity.toValue = 0.8
shadowOpacity.duration = 0.3
view.layer.add(shadowOpacity, forKey: nil)
view.layer.shadowOpacity = 0.8  // Set final value
```

### Mistake 3: Blocking Main Thread During Animation

**WRONG:**
```swift
// ❌ Heavy computation during animation causes stutter
UIView.animate(withDuration: 0.5, animations: {
    self.view.frame = newFrame
    self.expensiveComputation()  // Blocks main thread!
})
```

**CORRECT:**
```swift
// ✅ Move expensive work off main thread
DispatchQueue.global(qos: .userInitiated).async {
    let result = self.expensiveComputation()
    
    DispatchQueue.main.async {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.frame = newFrame
        })
    }
}
```

### Mistake 4: Not Cleaning Up Animations

**WRONG:**
```swift
// ❌ Memory leak: animation continues indefinitely
func startAnimation() {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.repeatCount = .infinity
    view.layer.add(animation, forKey: "opacity")
}
```

**CORRECT:**
```swift
// ✅ Properly manage animation lifecycle
func startAnimation() {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.repeatCount = .infinity
    view.layer.add(animation, forKey: "opacity")
}

func stopAnimation() {
    view.layer.removeAnimation(forKey: "opacity")
}

deinit {
    stopAnimation()
}
```

### Mistake 5: Ignoring Frame Rate and Performance

**WRONG:**
```swift
// ❌ Complex animation without optimization
UIView.animate(withDuration: 2.0, animations: {
    self.complexView.frame = newFrame  // Multiple subviews updating
    self.complexView.layoutIfNeeded()  // Forces layout during animation
})
```

**CORRECT:**
```swift
// ✅ Optimize before animating
complexView.layer.shouldRasterize = true
complexView.layer.rasterizationScale = UIScreen.main.scale

UIView.animate(withDuration: 2.0, animations: {
    self.complexView.frame = newFrame
}) { _ in
    self.complexView.layer.shouldRasterize = false
}
```

---

## 🔗 Related Topics
- [SwiftUI Advanced](../07-advanced/swiftui-advanced.md)
- [Performance Optimization](../07-advanced/advanced-performance.md)
- [Accessibility Guidelines](../10-accessibility/accessibility.md)
- [Gesture Recognition](../05-features/gesture-recognition.md)
