# Animation in Swift 🎬

## Overview

Animation brings user interfaces to life, providing visual feedback and guiding user attention. This guide covers both UIView animations for UIKit and SwiftUI's declarative animation system, including timing functions, spring physics, and common animation patterns essential for modern iOS development.

## Main Topics
- [UIView Animations](#uiview-animations) - Core Animation basics with UIKit
- [SwiftUI Animations](#swiftui-animations) - Declarative animation approach
- [Timing Functions](#timing-functions) - Easing and curve controls
- [Spring Animations](#spring-animations) - Physics-based motion
- [Gesture Animations](#gesture-animations) - Responding to user input
- [✅ Best Practices](#-best-practices) - Performance and UX patterns
- [❌ Common Mistakes](#-common-mistakes-anti-patterns) - Anti-patterns to avoid

## Official Documentation
- [Apple: UIView Animations](https://developer.apple.com/documentation/uikit/uiview#animations)
- [Apple: SwiftUI Animation](https://developer.apple.com/documentation/swiftui/animation)
- [Apple: Core Animation](https://developer.apple.com/documentation/quartzcore)
- [WWDC 2023: Animate with Springs](https://developer.apple.com/videos/play/wwdc2023/10054/)

---

## UIView Animations

### Basic UIView Animation Blocks

UIView animations provide straightforward property-based animation for UIKit views.

```swift
// ✅ Correct: Basic UIView animation block
import UIKit

class AnimationViewController: UIViewController {
    let button = UIButton()
    
    func animateButtonScale() {
        // Prepare initial state
        button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
            completion: { finished in
                print("Animation completed: \(finished)")
            }
        )
    }
    
    func chainedAnimations() {
        // First animation
        UIView.animate(withDuration: 0.5, animations: {
            self.button.backgroundColor = .red
        }) { finished in
            // Second animation after first completes
            UIView.animate(withDuration: 0.5) {
                self.button.backgroundColor = .blue
            }
        }
    }
    
    func complexAnimation() {
        UIView.animateKeyframes(
            withDuration: 2.0,
            delay: 0.0,
            options: .calculationModeLinear,
            animations: {
                // 0-50% of duration
                UIView.addKeyframe(
                    withRelativeStartTime: 0.0,
                    relativeDuration: 0.5,
                    animations: {
                        self.button.center.y -= 100
                    }
                )
                
                // 50-100% of duration
                UIView.addKeyframe(
                    withRelativeStartTime: 0.5,
                    relativeDuration: 0.5,
                    animations: {
                        self.button.center.x += 100
                    }
                )
            },
            completion: nil
        )
    }
}

// ❌ Wrong: Blocking main thread with Sleep
class BadAnimationViewController: UIViewController {
    func poorAnimation() {
        self.button.backgroundColor = .red
        Thread.sleep(forTimeInterval: 0.5)  // BLOCKS MAIN THREAD!
        self.button.backgroundColor = .blue
    }
}
```

### Spring Animations

```swift
// ✅ Correct: Spring animation parameters
func springAnimation() {
    UIView.animate(
        withDuration: 0.8,
        delay: 0.0,
        usingSpringWithDamping: 0.6,      // Lower = more bouncy (0.0-1.0)
        initialSpringVelocity: 0.5,       // Initial speed
        options: .curveEaseOut,
        animations: {
            self.button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    )
}

// ✅ Correct: Different spring profiles
func differentSprings() {
    // Subtle bounce
    let subtleSpring: CGFloat = 0.9
    
    // Medium bounce
    let mediumSpring: CGFloat = 0.7
    
    // Springy bounce
    let springySpring: CGFloat = 0.5
    
    // Tight/stiff response
    let tightSpring: CGFloat = 0.95
}
```

---

## SwiftUI Animations

### SwiftUI Declarative Animation

SwiftUI simplifies animations with declarative syntax.

```swift
// ✅ Correct: SwiftUI animation modifiers
import SwiftUI

struct AnimationView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            // Basic animation
            Button("Toggle") {
                isExpanded.toggle()
            }
            
            if isExpanded {
                Text("Expanded view")
                    .transition(.opacity)  // Fade in/out
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
            
            // Explicit animation scope
            Button("Animate") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        }
    }
}

// ✅ Correct: Complex transitions
struct AdvancedTransitionView: View {
    @State private var showDetail = false
    
    var body: some View {
        VStack {
            if showDetail {
                DetailView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            Button("Show Detail") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showDetail.toggle()
                }
            }
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("Detail content")
            .padding()
            .background(Color.blue.opacity(0.1))
    }
}

// ✅ Correct: Custom transitions
struct ScaleTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.5)
            .opacity(isActive ? 1.0 : 0.0)
    }
}

extension AnyTransition {
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}
```

### SwiftUI Value-Driven Animation

```swift
// ✅ Correct: Animating continuous values
struct ProgressAnimation: View {
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack {
            ProgressView(value: progress)
                .animation(.easeInOut(duration: 1.5), value: progress)
            
            Button("Animate Progress") {
                progress = 0.75
            }
        }
    }
}

// ✅ Correct: Animating multiple values
struct MultiValueAnimation: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: scale)
                .animation(.linear(duration: 2.0), value: rotation)
                .animation(.easeInOut(duration: 1.0), value: opacity)
            
            Button("Animate All") {
                scale = 1.2
                rotation = 360
                opacity = 0.5
            }
        }
    }
}

// ❌ Wrong: Animating without binding to state
struct BadProgressAnimation: View {
    var body: some View {
        VStack {
            ProgressView(value: 0.0)  // Static value, won't animate
        }
    }
}
```

---

## Timing Functions

### Curve Options

```swift
// ✅ Correct: Different timing curves
func demonstrateTimingCurves() {
    let curves: [UIView.AnimationOptions] = [
        .curveLinear,       // Constant speed
        .curveEaseIn,       // Slow start, fast end
        .curveEaseOut,      // Fast start, slow end
        .curveEaseInOut,    // Slow at both ends
    ]
    
    for curve in curves {
        UIView.animate(withDuration: 1.0, delay: 0, options: curve, animations: {
            // Animation changes speed based on curve
        })
    }
}

// ✅ Correct: SwiftUI animation curves
struct TimingCurveView: View {
    @State private var animate = false
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 50)
                .offset(y: animate ? 200 : 0)
                .animation(.linear(duration: 2.0), value: animate)
            
            Circle()
                .frame(width: 50)
                .offset(y: animate ? 200 : 0)
                .animation(.easeIn(duration: 2.0), value: animate)
            
            Circle()
                .frame(width: 50)
                .offset(y: animate ? 200 : 0)
                .animation(.easeOut(duration: 2.0), value: animate)
            
            Circle()
                .frame(width: 50)
                .offset(y: animate ? 200 : 0)
                .animation(.easeInOut(duration: 2.0), value: animate)
            
            Button("Toggle") {
                animate.toggle()
            }
        }
    }
}
```

### Custom Bezier Curves

```swift
// ✅ Correct: Custom UIBezierPath timing
func customTimingAnimation() {
    let customTiming = UIView.AnimationOptions(rawValue: 7 << 16)
    
    UIView.animate(
        withDuration: 1.0,
        delay: 0,
        options: customTiming,
        animations: {
            // Custom curve applied
        }
    )
}

// ✅ Correct: SwiftUI custom curve
struct CustomCurveAnimation: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
            .offset(y: animate ? 100 : 0)
            .animation(
                .cubic(
                    duration: 1.0,
                    controlPoint1: CGPoint(x: 0.25, y: 0.46),
                    controlPoint2: CGPoint(x: 0.45, y: 0.94)
                ),
                value: animate
            )
    }
}
```

---

## Spring Animations

### Physics-Based Motion

```swift
// ✅ Correct: Spring physics parameters
func springPhysics() {
    // response: duration of oscillation (lower = faster response)
    // dampingFraction: 0.0-1.0 (lower = more bouncy)
    
    let subtle = Animation.spring(response: 0.5, dampingFraction: 0.95)
    let medium = Animation.spring(response: 0.6, dampingFraction: 0.7)
    let bouncy = Animation.spring(response: 0.8, dampingFraction: 0.5)
}

// ✅ Correct: Spring animation with mass and stiffness
struct SpringAnimationView: View {
    @State private var pressed = false
    
    var body: some View {
        VStack {
            Button(action: { pressed.toggle() }) {
                Text("Press Me")
                    .scaleEffect(pressed ? 0.95 : 1.0)
                    .animation(
                        .spring(
                            response: 0.3,
                            dampingFraction: 0.6,
                            blendDuration: 0.0
                        ),
                        value: pressed
                    )
            }
        }
    }
}
```

---

## Gesture Animations

### Responding to User Interactions

```swift
// ✅ Correct: Gesture-driven animations
struct GestureAnimationView: View {
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 100)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                scale = 1.0
                            }
                        }
                )
            
            Rectangle()
                .frame(height: 100)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                )
        }
    }
}

// ✅ Correct: Pan gesture with custom animation
struct PanGestureView: View {
    @State private var position: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            Circle()
                .frame(width: 50)
                .offset(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            position = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(
                                .interpolatingSpring(
                                    mass: 1.0,
                                    stiffness: 50.0,
                                    damping: 5.0,
                                    initialVelocity: 0.0
                                )
                            ) {
                                position = .zero
                            }
                        }
                )
        }
    }
}

// ❌ Wrong: Animations outside gesture handlers
struct BadGestureAnimation: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .frame(width: 100)
            .scaleEffect(scale)
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        scale = 1.2  // No animation!
                    }
            )
    }
}
```

---

## ✅ Best Practices

### Keep Animations Performant

**DO:**
```swift
// Animate simple properties
UIView.animate(withDuration: 0.3) {
    view.alpha = 0.5
    view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
}

// Use CADisplayLink for complex animations
var displayLink: CADisplayLink?

func startComplexAnimation() {
    displayLink = CADisplayLink(
        target: self,
        selector: #selector(updateFrame)
    )
    displayLink?.add(to: .main, forMode: .common)
}

@objc func updateFrame() {
    // Update animation frame
}
```

### Provide Visual Feedback

**DO:**
```swift
// Immediate visual feedback during interactions
Button(action: { }) {
    Text("Tap")
}
.contentShape(Rectangle())
.onTapGesture {
    withAnimation(.easeInOut(duration: 0.2)) {
        isSelected.toggle()
    }
}
```

### Use Appropriate Durations

**DO:**
```swift
// Snappy feedback: 0.1-0.3 seconds
withAnimation(.easeInOut(duration: 0.2)) {
    isActive.toggle()
}

// Noticeable transition: 0.3-0.5 seconds
withAnimation(.easeInOut(duration: 0.4)) {
    showDetail.toggle()
}

// Smooth entrance: 0.5-0.8 seconds
withAnimation(.spring(response: 0.6)) {
    appear = true
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake: Blocking Main Thread

**WRONG:**
```swift
// DON'T: Sleep on main thread
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.label.text = "Updated"
}

// Use animations instead
Thread.sleep(forTimeInterval: 0.5)
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0.5
}
```

**CORRECT:**
```swift
// DO: Use animation blocks
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0.5
} completion: { _ in
    self.label.text = "Updated"
}
```

### Mistake: Animating Frame Directly

**WRONG:**
```swift
// DON'T: Animate frame (creates layout issues)
UIView.animate(withDuration: 0.5) {
    self.view.frame.origin.y += 100
}
```

**CORRECT:**
```swift
// DO: Use constraints or transform
UIView.animate(withDuration: 0.5) {
    self.view.transform = CGAffineTransform(translationX: 0, y: 100)
    // Or update layout constraints
}
```

### Mistake: Missing Value Parameter in SwiftUI

**WRONG:**
```swift
// DON'T: Animation without value parameter
if isExpanded {
    Text("Details")
        .animation(.easeInOut(duration: 0.3))  // Won't animate!
}
```

**CORRECT:**
```swift
// DO: Specify animation value
if isExpanded {
    Text("Details")
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
}

// Or use withAnimation
Button("Toggle") {
    withAnimation(.easeInOut(duration: 0.3)) {
        isExpanded.toggle()
    }
}
```

### Mistake: Excessive Animation Duration

**WRONG:**
```swift
// DON'T: Overly long animations feel sluggish
UIView.animate(withDuration: 5.0) {
    self.view.alpha = 0.5
}
```

**CORRECT:**
```swift
// DO: Use appropriate duration
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0.5
}
```

---

## 🔗 Related Topics

- [**01-fundamentals/fundamentals.md**](fundamentals.md) - Swift types and control flow
- [**01-fundamentals/object-oriented-programming.md**](object-oriented-programming.md) - Classes and structs
- [**07-advanced/swiftui-advanced.md**](../07-advanced/swiftui-advanced.md) - Advanced SwiftUI techniques
- [**05-features/user-interface-frameworks.md**](../05-features/user-interface-frameworks.md) - UIKit and SwiftUI
- [**07-advanced/advanced-performance.md**](../07-advanced/advanced-performance.md) - Performance optimization
