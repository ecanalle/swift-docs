# Accessibility - Inclusive App Design

## Overview

Accessibility ensures your app is usable by everyone, including people with disabilities. VoiceOver, Dynamic Type, and High Contrast support are essential.

## Main Topics

- [VoiceOver Support](#voiceover-support)
- [Dynamic Type](#dynamic-type)
- [Color and Contrast](#color-and-contrast)
- [Keyboard Navigation](#keyboard-navigation)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Accessibility](https://developer.apple.com/documentation/accessibility)

---

## VoiceOver Support

### Adding Accessibility Labels

```swift
import UIKit

class AccessibleViewController: UIViewController {
    let button = UIButton()
    let textField = UITextField()
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        // Button
        button.accessibilityLabel = "Submit"
        button.accessibilityHint = "Sends form data"
        button.accessibilityTraits = .button
        
        // Text Field
        textField.accessibilityLabel = "Email Address"
        textField.accessibilityHint = "Enter your email"
        
        // Image View
        imageView.accessibilityLabel = "Profile Photo"
        imageView.accessibilityTraits = .image
        
        // Custom View
        let customView = UIView()
        customView.accessibilityLabel = "Information Section"
        customView.accessibilityTraits = .staticText
    }
}
```

### VoiceOver Custom Actions

```swift
import UIKit

class VoiceOverActionsViewController: UIViewController {
    let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVoiceOverActions()
    }
    
    private func setupVoiceOverActions() {
        label.accessibilityLabel = "Item"
        
        let deleteAction = UIAccessibilityCustomAction(
            name: "Delete",
            target: self,
            selector: #selector(deleteItem)
        )
        
        let shareAction = UIAccessibilityCustomAction(
            name: "Share",
            target: self,
            selector: #selector(shareItem)
        )
        
        label.accessibilityCustomActions = [deleteAction, shareAction]
    }
    
    @objc func deleteItem() {
        print("Item deleted")
    }
    
    @objc func shareItem() {
        print("Item shared")
    }
}
```

---

## Dynamic Type

### SwiftUI Dynamic Type

```swift
import SwiftUI

struct DynamicTypeView: View {
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        VStack(spacing: 16) {
            // Uses system font sizes that scale with Dynamic Type
            Text("Headline")
                .font(.headline)
            
            Text("Body Text")
                .font(.body)
            
            Text("Caption")
                .font(.caption)
            
            // Custom scaled font
            Text("Custom sized")
                .font(.system(size: 16, weight: .regular))
                .allowsTightening(true)
            
            // Conditionally adjust for large sizes
            VStack {
                if sizeCategory.isAccessibilityCategory {
                    VStack {
                        Image(systemName: "star")
                        Text("Large Text Mode")
                    }
                } else {
                    HStack {
                        Image(systemName: "star")
                        Text("Standard Mode")
                    }
                }
            }
        }
        .padding()
    }
}
```

### UIKit Dynamic Type

```swift
import UIKit

class DynamicTypeViewController: UIViewController {
    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDynamicType()
    }
    
    private func setupDynamicType() {
        // Use preferred fonts that scale
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        
        // Adjust for content size changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateForContentSizeChange),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil
        )
    }
    
    @objc func updateForContentSizeChange() {
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        bodyLabel.font = .preferredFont(forTextStyle: .body)
    }
}
```

---

## Color and Contrast

### High Contrast Support

```swift
import UIKit

class HighContrastViewController: UIViewController {
    @available(iOS 13.0, *)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHighContrast()
    }
    
    @available(iOS 13.0, *)
    private func setupHighContrast() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let isHighContrast = traitCollection.accessibilityContrast == .high
        
        if isHighContrast {
            // Use higher contrast colors
            view.backgroundColor = isDarkMode ? .black : .white
        } else {
            view.backgroundColor = isDarkMode ? .darkGray : .lightGray
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupHighContrast()
    }
}
```

### SwiftUI Contrast Support

```swift
import SwiftUI

struct ContrastView: View {
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    var body: some View {
        VStack {
            if colorSchemeContrast == .increased {
                Text("High Contrast Mode")
                    .font(.title)
                    .foregroundColor(.primary)
            } else {
                Text("Standard Contrast")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

---

## Keyboard Navigation

### Tab Navigation

```swift
import SwiftUI

struct KeyboardNavigationView: View {
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .password }
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .onSubmit { login() }
            
            Button("Login") {
                login()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
    
    func login() {
        print("Login with \(email)")
    }
}
```

### UIKit Keyboard Navigation

```swift
import UIKit

class KeyboardAccessibleViewController: UIViewController {
    @IBOutlet weak var firstField: UITextField!
    @IBOutlet weak var secondField: UITextField!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardNavigation()
    }
    
    private func setupKeyboardNavigation() {
        // Set tab order
        firstField.accessibilitySelectAction = { [weak self] in
            self?.firstField.becomeFirstResponder()
            return true
        }
        
        // Return key moves to next field
        firstField.returnKeyType = .next
        secondField.returnKeyType = .done
    }
}
```

---

## 🎯 Best Practices

### 1. Always Add Labels
```swift
// ✅ VoiceOver can announce
button.accessibilityLabel = "Delete"

// ❌ No label for VoiceOver
button.accessibilityLabel = nil
```

### 2. Use Preferred Fonts
```swift
// ✅ Scales with Dynamic Type
label.font = .preferredFont(forTextStyle: .body)

// ❌ Fixed size doesn't scale
label.font = .systemFont(ofSize: 16)
```

### 3. Test with Accessibility Inspector
```swift
// ✅ Use Accessibility Inspector
// Xcode > Xcode > Open Developer Tools > Accessibility Inspector

// ❌ Assume accessibility works
```

---

## ❌ Common Mistakes

### Mistake 1: Missing Accessibility Labels

**WRONG:**
```swift
// ❌ No label
button.isAccessibilityElement = true
// VoiceOver: "Button"
```

**CORRECT:**
```swift
// ✅ Descriptive label
button.accessibilityLabel = "Delete Item"
button.accessibilityHint = "Removes this item permanently"
```

---

### Mistake 2: Fixed Font Sizes

**WRONG:**
```swift
// ❌ Doesn't scale for accessibility
label.font = .systemFont(ofSize: 14)
```

**CORRECT:**
```swift
// ✅ Scales with settings
label.font = .preferredFont(forTextStyle: .body)
```

---

### Mistake 3: Color-Only Indicators

**WRONG:**
```swift
// ❌ Only uses color
if isValid {
    textField.textColor = .green
}
```

**CORRECT:**
```swift
// ✅ Use icon and text too
if isValid {
    textField.textColor = .green
    textField.accessibilityLabel = "Valid email"
}
```

---

## Related Topics

- [Dark Mode and Appearance](dark-mode-appearance.md)
- [SwiftUI Basics](../05-features/swiftui-basics.md)
- [UIKit Fundamentals](uikit.md)

---

**Build inclusive apps for everyone!**
