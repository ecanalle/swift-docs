# Animations and Transitions

## Overview

Animations bring the UI to life with smooth transitions and visual effects. SwiftUI provides declarative animations while UIKit uses explicit animation blocks.

## Main Topics

- [SwiftUI Animations](#swiftui-animations)
- [UIView Animations](#uiview-animations)
- [CABasicAnimation](#cabasicanimation)
- [Transition Effects](#transition-effects)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Animations](https://developer.apple.com/documentation/swiftui/animation)
- [CABasicAnimation](https://developer.apple.com/documentation/quartzcore/cabasicanimation)

---

## SwiftUI Animations

### Basic Animations

```swift
import SwiftUI

struct BasicAnimationView: View {
    @State private var isScaled = false
    @State private var rotation: Double = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Scale animation
            Circle()
                .fill(.blue)
                .frame(width: 50, height: 50)
                .scaleEffect(isScaled ? 1.5 : 1.0)
                .onTapGesture {
                    withAnimation {
                        isScaled.toggle()
                    }
                }
            
            // Rotation animation
            Image(systemName: "gear")
                .font(.title)
                .rotationEffect(.degrees(rotation))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 1)) {
                        rotation = rotation == 0 ? 360 : 0
                    }
                }
            
            // Position animation
            Rectangle()
                .fill(.green)
                .frame(width: 100, height: 50)
                .offset(x: offset)
                .onTapGesture {
                    withAnimation(.spring()) {
                        offset = offset == 0 ? 100 : 0
                    }
                }
        }
    }
}
```

### Animation Curves and Timing

```swift
import SwiftUI

struct AnimationTimingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Linear
            RoundedRectangle(cornerRadius: 10)
                .fill(.red)
                .frame(height: 50)
                .offset(x: isAnimating ? 200 : 0)
            
            // Ease in out
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue)
                .frame(height: 50)
                .offset(x: isAnimating ? 200 : 0)
                .animation(.easeInOut(duration: 2), value: isAnimating)
            
            // Spring
            RoundedRectangle(cornerRadius: 10)
                .fill(.green)
                .frame(height: 50)
                .offset(x: isAnimating ? 200 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
            
            Button("Animate") {
                isAnimating.toggle()
            }
        }
        .padding()
    }
}
```

---

## UIView Animations

### UIView Animation Blocks

```swift
import UIKit

class UIViewAnimationViewController: UIViewController {
    let box = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        box.backgroundColor = .blue
        box.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        view.addSubview(box)
    }
    
    func animateBox() {
        // Basic animation
        UIView.animate(withDuration: 0.5) {
            self.box.center.x += 200
        }
    }
    
    func animateWithCompletion() {
        UIView.animate(withDuration: 0.5, animations: {
            self.box.alpha = 0.5
            self.box.transform = CGAffineTransform(scaleX: 2, y: 2)
        }, completion: { finished in
            print("Animation completed: \(finished)")
        })
    }
    
    func springAnimation() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.box.center.y += 300
            }
        )
    }
}
```

---

## CABasicAnimation

### Core Animation

```swift
import UIKit

class CAAnimationViewController: UIViewController {
    let shapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let circle = UIView()
        circle.layer.addSublayer(shapeLayer)
        view.addSubview(circle)
    }
    
    func animatePosition() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = CGPoint(x: 100, y: 100)
        animation.toValue = CGPoint(x: 300, y: 500)
        animation.duration = 2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        shapeLayer.add(animation, forKey: "positionAnimation")
    }
    
    func animateOpacity() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.autoreverses = true
        
        shapeLayer.add(animation, forKey: "opacityAnimation")
    }
    
    func animateScale() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 2.0
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.autoreverses = true
        
        shapeLayer.add(animation, forKey: "scaleAnimation")
    }
}
```

---

## Transition Effects

### SwiftUI Transitions

```swift
import SwiftUI

struct TransitionView: View {
    @State private var showContent = false
    
    var body: some View {
        VStack {
            if showContent {
                // Slide transition
                Text("Slide In")
                    .transition(.slide)
                
                // Scale with opacity
                Text("Scale")
                    .transition(.scale)
                
                // Custom transition
                Text("Custom")
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
            
            Button("Toggle") {
                withAnimation {
                    showContent.toggle()
                }
            }
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Use Appropriate Duration
```swift
// ✅ 0.3-0.5 seconds feel responsive
withAnimation(.easeInOut(duration: 0.3)) {
    state = !state
}

// ❌ Too long animations feel sluggish
```

### 2. Animate State Changes
```swift
// ✅ Animate bound to state
@State var isExpanded = false

if isExpanded {
    Text("Expanded")
        .transition(.scale)
}

// ❌ Only animate when needed, not constantly
```

### 3. Use CATransaction for Control
```swift
// ✅ Group related animations
CATransaction.begin()
CATransaction.setCompletionBlock { print("Done") }

// Animations here
animation.duration = 1

CATransaction.commit()
```

---

## ❌ Common Mistakes

### Mistake 1: Animating on Layout

**WRONG:**
```swift
// ❌ Animation happens on every layout pass
VStack {
    withAnimation {  // Wrong place
        content
    }
}
```

**CORRECT:**
```swift
// ✅ Animate on state change
@State var isExpanded = false

if isExpanded {
    content
        .transition(.scale)
}

Button("Expand") {
    withAnimation { isExpanded.toggle() }
}
```

---

### Mistake 2: Not Removing Animations

**WRONG:**
```swift
// ❌ Animation never stops
animation.repeatCount = .infinity
shapeLayer.add(animation, forKey: nil)
// Still animating in memory
```

**CORRECT:**
```swift
// ✅ Remove when done
animation.repeatCount = 1
shapeLayer.add(animation, forKey: "myAnimation")

// Later: shapeLayer.removeAnimation(forKey: "myAnimation")
```

---

## Related Topics

- [SwiftUI Advanced](../05-features/swiftui-advanced.md)
- [Core Graphics](.)
- [Performance Optimization](../07-advanced/performance-optimization.md)

---

**Create fluid, delightful animations!**
