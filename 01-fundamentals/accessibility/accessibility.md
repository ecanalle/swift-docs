# Accessibility Fundamentals

## Overview

Creating accessible apps ensures they're usable by everyone, including people with disabilities. Accessibility in iOS is fundamental, not a feature add-on, and directly impacts your app's market reach and legal compliance.

## Main Topics

- [Accessibility Basics](#accessibility-basics)
- [VoiceOver Support](#voiceover-support)
- [Dynamic Type](#dynamic-type)
- [Contrast and Color](#contrast-and-color)
- [Motor Accessibility](#motor-accessibility)
- [Hearing Accessibility](#hearing-accessibility)
- [Testing Accessibility](#testing-accessibility)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Accessibility Guidelines - Apple](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Standards](https://www.w3.org/WAI/WCAG21/quickref/)
- [UIAccessibility API](https://developer.apple.com/documentation/uikit/accessibility)

---

## Accessibility Basics

### VoiceOver Introduction

VoiceOver is Apple's screen reader technology that speaks interface elements:

```swift
// Make views accessible to VoiceOver
let button = UIButton()
button.setTitle("Save", for: .normal)

// Add accessibility label (what VoiceOver says)
button.accessibilityLabel = "Save document"

// Add accessibility hint (additional context)
button.accessibilityHint = "Saves your changes"

// Mark as button (so VoiceOver says "button")
button.accessibilityTraits = .button

// Custom action
button.accessibilityCustomActions = [
    UIAccessibilityCustomAction(name: "Quick Save") { _ in
        self.quickSave()
        return true
    }
]
```

### SwiftUI Accessibility

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button(action: { }) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .accessibilityLabel("Save document")
            .accessibilityHint("Saves your changes")
            
            Image("profile")
                .accessibilityLabel("User profile picture")
                .accessibilityHidden(false)  // Usually images need labels
            
            Text("Loading...")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading content")
        }
    }
}
```

---

## VoiceOver Support

### Accessibility Traits

```swift
// Button
button.accessibilityTraits = .button

// Link
link.accessibilityTraits = .link

// Image
imageView.accessibilityTraits = .image

// Disabled element
disabledButton.accessibilityTraits = [.button, .notEnabled]

// Multiple traits
checkbox.accessibilityTraits = [.button, .toggleButton]

// Combined with label
saveButton.accessibilityLabel = "Save"
saveButton.accessibilityTraits = .button
saveButton.accessibilityHint = "Saves document to cloud"
```

### Grouping Elements

```swift
// UIKit: Use container view
let container = UIView()
container.isAccessibilityElement = true
container.accessibilityLabel = "User info"
container.accessibilityValue = "John Doe, 30 years old"

// SwiftUI: Use AccessibilityElement with children
VStack {
    Text("John Doe")
    Text("30 years old")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("User information")

// Or use custom containers
VStack {
    Text("John Doe")
    Text("30 years old")
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("John Doe, 30 years old")
```

### Providing Context

```swift
// Bad - too vague
button.accessibilityLabel = "Delete"

// Better - provides context
button.accessibilityLabel = "Delete message"
button.accessibilityHint = "Removes this message permanently"

// SwiftUI
Button(role: .destructive) {
    deleteMessage()
} label: {
    Label("Delete", systemImage: "trash")
}
.accessibilityLabel("Delete message")
.accessibilityHint("Removes this message permanently")
```

---

## Dynamic Type

Making apps respond to user's text size preferences:

```swift
// UIKit
let label = UILabel()
label.font = UIFont.preferredFont(forTextStyle: .body)  // Responds to user size

label.adjustsFontForContentSizeCategory = true  // Update when user changes setting

// SwiftUI - automatic with standard fonts
VStack {
    Text("Headline")
        .font(.headline)
    
    Text("Body")
        .font(.body)
    
    Text("Caption")
        .font(.caption)
}  // All respond to Dynamic Type automatically

// Custom sizes with relative scaling
let scaledFont = UIFont.preferredFont(forTextStyle: .body)
let pointSize = scaledFont.pointSize * 1.2

// SwiftUI custom font with scaling
Text("Custom Text")
    .font(.system(.body, design: .default))
    .lineLimit(nil)
    .fixedSize(horizontal: false, vertical: true)
```

### Testing Dynamic Type

```swift
// UIKit - Accessibility Inspector test sizes
// In Xcode Scheme: Edit Scheme > Run > Arguments Passed:
// -com.apple.CoreHaptics.SessionDriver 1
// -AppleTextDirection 0
// -com.apple.CoreData.SQLDebug 1

// Manually change text size in Settings > Accessibility > Larger Accessibility Sizes

// Verify layout works at all sizes
func testTextSizeVariations() {
    let sizes: [UIContentSizeCategory] = [
        .extraSmall, .small, .medium, .large, .extraLarge,
        .extraExtraLarge, .extraExtraExtraLarge,
        .accessibilityMedium, .accessibilityLarge,
        .accessibilityExtraLarge, .accessibilityExtraExtraLarge
    ]
    
    for size in sizes {
        // Test layout at each size
        print("Testing at size: \(size.rawValue)")
    }
}
```

---

## Contrast and Color

### Color Contrast

```swift
// WCAG AA standard: 4.5:1 ratio for normal text, 3:1 for large text
// WCAG AAA standard: 7:1 ratio for normal text, 4.5:1 for large text

// Good contrast
let goodText = UIColor.black
let goodBackground = UIColor.white
// Ratio: ~21:1 ✅

// Poor contrast (avoid)
let badText = UIColor.gray
let badBackground = UIColor.lightGray
// Ratio: ~2:1 ❌

// SwiftUI - use semantic colors
Text("Error Message")
    .foregroundColor(.red)
    .background(Color.white)

// With accessibility colors
Text("Important")
    .foregroundColor(.systemRed)
    .background(Color.systemBackground)
```

### Not Using Color Alone

```swift
// Don't convey information with color alone
// Bad example:
HStack {
    Circle().fill(Color.red)      // Only red indicates error
    Text("Error")
}

// Better example:
HStack {
    Image(systemName: "exclamationmark.circle.fill")
        .foregroundColor(.red)
    Text("Error")
    Image(systemName: "xmark")
}  // Uses icon + color + text

// Status indicator example
// Bad: Only green/red
// Good: Icon + label + color
VStack {
    Image(systemName: "wifi.circle.fill")
        .foregroundColor(.green)
    Text("Connected")
}
```

---

## Motor Accessibility

### Touch Target Sizes

```swift
// Apple minimum: 44x44 points (minimum)
// Recommended: 50x50+ for better accessibility

// UIKit
button.frame.size = CGSize(width: 50, height: 50)
button.layer.cornerRadius = 25

// SwiftUI
Button(action: { }) {
    Image(systemName: "plus")
        .font(.system(size: 20))
}
.frame(width: 50, height: 50)  // Minimum 44x44
.background(Color.blue)
.clipShape(Circle())

// Spacing between touch targets
VStack(spacing: 16) {  // At least 16 points between buttons
    Button("Save") { }
    Button("Cancel") { }
    Button("Delete") { }
}
```

### Alternatives to Gesture-Based Controls

```swift
// Provide alternatives to complex gestures
// Instead of requiring swipe, pinch, long-press

// Long press
let longPress = UILongPressGestureRecognizer()
longPress.addTarget(self, action: #selector(handleLongPress))
view.addGestureRecognizer(longPress)

// Also provide button alternative
let actionButton = UIButton()
actionButton.addTarget(self, action: #selector(handleLongPress), for: .touchUpInside)

// SwiftUI context menu
VStack {
    Text("Item")
        .contextMenu {
            Button(action: { }) {
                Label("Delete", systemImage: "trash")
            }
        }
}

// Also provide explicit button
Button("Delete", action: { })
```

---

## Hearing Accessibility

### Captions and Subtitles

```swift
import AVFoundation

// Ensure captions are available
let asset = AVAsset(url: videoURL)

// Enable captions by default
let playerConfig = AVPlayerViewController.AccessibilityConfiguration()
// Captions enabled in player

// For audio-only content
let audioDescriptionTrack = AVMediaSelectionOption()  // Provide audio description

// SwiftUI - using AVPlayer
struct VideoPlayer: View {
    @State private var isPlayButtonVisible = true
    
    var body: some View {
        // Show captions by default
        Text("Video with captions enabled")
    }
}
```

### Audio Alerts

```swift
// Don't rely only on sounds
// Always provide visual feedback too

// Bad: Only sound indication
AudioToolbox.AudioServicesPlaySystemSound(1000)

// Better: Sound + haptic + visual
func provideNotification() {
    // Sound
    AudioToolbox.AudioServicesPlaySystemSound(1000)
    
    // Haptic feedback
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    
    // Visual feedback
    showNotificationBanner("Action completed")
}

// Announce important changes to VoiceOver
UIAccessibility.post(notification: .announcement, argument: "Upload complete")
```

---

## Testing Accessibility

### Using Accessibility Inspector

```swift
// Launch Accessibility Inspector (Xcode > Tools > Accessibility Inspector)
// Can inspect any app and see:
// - Accessibility labels
// - Traits
// - Hints
// - Values
// - Frame information

// Common issues found:
// 1. Missing accessibility labels on images
// 2. Contrast ratio violations
// 3. Touch targets too small
// 4. No support for Dynamic Type
// 5. No VoiceOver support
```

### Automated Testing

```swift
// XCUITest accessibility testing
func testAccessibilityOfLoginScreen() {
    let app = XCUIApplication()
    app.launch()
    
    // Find by accessibility identifier
    let emailTextField = app.textFields["emailInput"]
    XCTAssertTrue(emailTextField.exists)
    
    // Verify accessibility label
    let loginButton = app.buttons["Log In"]
    XCTAssertEqual(loginButton.label, "Log In")
    
    // Test with VoiceOver enabled
    app.settingsScreens.accessibility.tap()
    // Run tests with VoiceOver on
}
```

---

## 🎯 Best Practices

### 1. Make Accessibility Part of Design
- Not an afterthought
- Test with assistive technologies from the start

### 2. Support VoiceOver
- All images need labels
- Buttons need clear actions
- Groups need meaningful descriptions

### 3. Support Dynamic Type
- Use system fonts
- Allow text to wrap
- Test at all sizes

### 4. Provide Multiple Ways
- Don't rely on single input method
- Gesture + button alternatives
- Color + icons + text

### 5. Test with Real Users
- Real assistive technology users
- Different disabilities
- Real-world scenarios

---

## ❌ Common Mistakes

### Mistake 1: Missing Image Labels

**WRONG:**
```swift
Image("logo")
    // No accessibility label - VoiceOver says "image, logo"
```

**CORRECT:**
```swift
Image("logo")
    .accessibilityLabel("Apple Log")
    .accessibilityHidden(false)
```

---

### Mistake 2: Not Supporting Dynamic Type

**WRONG:**
```swift
label.font = UIFont(name: "CustomFont", size: 14)  // Ignores user size
```

**CORRECT:**
```swift
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true
```

---

### Mistake 3: Color-Only Indicators

**WRONG:**
```swift
if status == .error {
    label.textColor = .red  // Only red shows problem
}
```

**CORRECT:**
```swift
if status == .error {
    label.text = "❌ Error"
    label.textColor = .red
}
```

---

## Related Topics

- [UIView Customization](../../04-app-lifecycle/uiview-customization.md)
- [Design Systems](../../02-architecture/design-systems.md)
- [Internationalization](../../localization-i18n/)

---

**Build inclusive apps that work for everyone!**
