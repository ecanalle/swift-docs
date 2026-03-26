# Dark Mode and Appearance - Adaptive UI

## Overview

Dark Mode and Appearance provide adaptive UI that responds to system settings. Apps can support light, dark, and custom appearance modes.

## Main Topics

- [Detecting Appearance Changes](#detecting-appearance-changes)
- [Custom Colors and Assets](#custom-colors-and-assets)
- [SwiftUI Dark Mode](#swiftui-dark-mode)
- [Dynamic Color](#dynamic-color)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Appearance](https://developer.apple.com/documentation/uikit/uiappearance)
- [Environment Values](https://developer.apple.com/documentation/swiftui/environmentvalues)

---

## Detecting Appearance Changes

### UIKit Dark Mode Detection

```swift
import UIKit

class DarkModeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearanceObserver()
        updateForCurrentAppearance()
    }
    
    private func setupAppearanceObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceDidChange),
            name: UITraitCollection.traitCollectionDidChangeNotification,
            object: nil
        )
    }
    
    @objc func appearanceDidChange() {
        updateForCurrentAppearance()
    }
    
    private func updateForCurrentAppearance() {
        let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            view.backgroundColor = .systemBackground  // Auto-adapts
            // Or use dark mode specific colors
        } else {
            view.backgroundColor = .systemBackground
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateForCurrentAppearance()
        }
    }
}
```

### Manual Appearance Override

```swift
import UIKit

class CustomAppearanceController: UIViewController {
    override var preferredUserInterfaceStyle: UIUserInterfaceStyle {
        return .dark  // Force dark mode
        // Options: .light, .dark, .unspecified (system default)
    }
}
```

---

## Custom Colors and Assets

### Color Set in Assets

```swift
import UIKit

class ColorManager {
    // Define colors for light and dark modes in Assets.xcassets
    // Use Color Set with different appearances
    
    static let brandColor = UIColor(named: "BrandColor")!
    static let backgroundColor = UIColor(named: "BackgroundColor")!
    static let textColor = UIColor(named: "TextColor")!
    
    // Or create dynamically
    static func systemAdaptiveColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
}

// Usage
class StyledViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ColorManager.backgroundColor
    }
}
```

### Dynamic System Colors

```swift
import UIKit

class SystemColorView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // System colors that adapt automatically
        let label = UILabel()
        label.textColor = .label  // Adapts light/dark
        
        let background = UIView()
        background.backgroundColor = .systemBackground
        
        let secondary = UIView()
        secondary.backgroundColor = .secondarySystemBackground
        
        let tertiaryBackground = UIView()
        tertiaryBackground.backgroundColor = .tertiarySystemBackground
    }
}
```

---

## SwiftUI Dark Mode

### SwiftUI Dark Mode Detection

```swift
import SwiftUI

struct DarkModeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if colorScheme == .dark {
                Text("Dark Mode Active")
                    .foregroundColor(.white)
            } else {
                Text("Light Mode Active")
                    .foregroundColor(.black)
            }
            
            Color.adaptiveView()
        }
    }
}

struct AdaptiveColorView: View {
    var body: some View {
        VStack {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? .darkGray
                    : .lightGray
            })
        }
    }
}
```

### Custom Appearance Modifier

```swift
import SwiftUI

struct DarkModeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                content
                    .preferredColorScheme(.dark)
            } else {
                content
                    .preferredColorScheme(.light)
            }
        }
    }
}

extension View {
    func adaptiveColorScheme() -> some View {
        modifier(DarkModeModifier())
    }
}

// Usage
struct ContentView: View {
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                Text("Adaptive Content")
                    .foregroundColor(.primary)
            }
        }
        .adaptiveColorScheme()
    }
}
```

---

## Dynamic Color

### Creating Adaptive Assets

```swift
import SwiftUI

// In Assets: Create Color Set with both Light and Dark variants

struct AdaptiveContent: View {
    var body: some View {
        VStack(spacing: 20) {
            // Using named color from Assets
            Text("Using Asset Color")
                .foregroundColor(Color("AdaptiveText"))
            
            // Using environment
            VStack {
                Text("Automatic adaptation")
            }
            .background(Color(.systemBackground))
            
            // Manual adaptation
            ZStack {
                Color(.systemGray6)
                Text("Gray 6")
                    .foregroundColor(.primary)
            }
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Use System Colors
```swift
// ✅ System colors adapt automatically
view.backgroundColor = .systemBackground
label.textColor = .label

// ❌ Fixed colors don't adapt
view.backgroundColor = .white
label.textColor = .black
```

### 2. Test Both Modes
```swift
// ✅ Test with both schemes
struct PreviewContainer: View {
    var body: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}

// ❌ Only test one mode
```

### 3. Use Color Assets
```swift
// ✅ Define in Assets with variants
Color("BrandColor")

// ❌ Hardcode colors everywhere
Color(red: 0.2, green: 0.4, blue: 0.8)
```

---

## ❌ Common Mistakes

### Mistake 1: Not Using System Colors

**WRONG:**
```swift
// ❌ Doesn't adapt to dark mode
view.backgroundColor = .white
label.textColor = .black
```

**CORRECT:**
```swift
// ✅ Adapts automatically
view.backgroundColor = .systemBackground
label.textColor = .label
```

---

### Mistake 2: Not Testing Dark Mode

**WRONG:**
```swift
// ❌ Only works in light mode
Text("Dark text")
    .foregroundColor(.black)
```

**CORRECT:**
```swift
// ✅ Works in both modes
Text("Adaptive text")
    .foregroundColor(.primary)
```

---

## Related Topics

- [SwiftUI Basics](../05-features/swiftui-basics.md)
- [SwiftUI Advanced](../05-features/swiftui-advanced.md)
- [Custom Views](.)

---

**Support dark mode and accessibility!**
